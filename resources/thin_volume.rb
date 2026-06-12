# frozen_string_literal: true
#
# Cookbook:: lvm
# Resource:: thin_volume
#
# Copyright:: 2024, Sous Chefs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Creates an LVM thin logical volume from a pre-existing thin pool.
#
# A thin volume:
#   - Has a *virtual* size that can exceed available VG free space (over-provisioning)
#   - Must reference an existing lvm_thin_pool via the :pool property
#   - Supports optional filesystem creation, LUKS encryption, and mount points
#     (same as lvm_logical_volume via the shared _lv_filesystem partial)
#   - Supports :resize to change virtual size
#
# Usage:
#   lvm_thin_volume 'datalv' do
#     group      'datavg'
#     pool       'thinpool'
#     size       '50G'
#     filesystem 'xfs'
#     mount_point '/data'
#   end
#
# Or nested inside lvm_thin_pool:
#   lvm_thin_pool 'thinpool' do
#     group  'datavg'
#     size   '20G'
#     thin_volumes [
#       lvm_thin_volume('thinlv') { group 'datavg'; pool 'thinpool'; size '50G' }
#     ]
#   end

unified_mode true

use 'partial/_lv_common'      # group, size, physical_volumes, wipe_signatures, ignore_skipped_cluster
use 'partial/_lv_filesystem'  # filesystem, filesystem_params, mount_point, encrypt_with_luks, luks_version, password

# ----------------------------------------------------------------------------
# Resource-specific properties
# ----------------------------------------------------------------------------

property :name, String, name_property: true,
                        description: 'Name of the thin logical volume'

property :pool, String,
         description: 'Name of the thin pool to provision this volume from'

# ----------------------------------------------------------------------------
# action_class helpers
# ----------------------------------------------------------------------------

action_class do
  include LvmActionHelpers

  def lv_key
    "#{new_resource.group}/#{new_resource.name}"
  end

  def lv_dev_path
    "/dev/#{new_resource.group}/#{new_resource.name}"
  end

  def lv_data
    current_lvs[lv_key]
  end

  def lv_exists?
    !lv_data.nil?
  end

  def pool_key
    "#{new_resource.group}/#{new_resource.pool}"
  end

  def validate_create!
    raise 'lvm_thin_volume: group is required' if new_resource.group.nil?
    raise 'lvm_thin_volume: pool is required'  if new_resource.pool.nil?
    raise 'lvm_thin_volume: size is required'  if new_resource.size.nil?

    raise "Volume group '#{new_resource.group}' does not exist!" \
      unless current_vgs.key?(new_resource.group)

    raise "Thin pool '#{pool_key}' does not exist! Create lvm_thin_pool '#{new_resource.pool}' first." \
      unless current_lvs.key?(pool_key)

    if new_resource.mount_point.is_a?(Hash)
      loc = new_resource.mount_point[:location] || new_resource.mount_point['location']
      raise 'lvm_thin_volume: mount_point Hash must include :location' unless loc
    end
  end
end

# ----------------------------------------------------------------------------
# :create
# ----------------------------------------------------------------------------

action :create do
  validate_create!

  # -- 1. Create thin volume ----------------------------------------------------
  unless lv_exists?
    converge_by("Create thin volume #{lv_key} (virtualsize #{new_resource.size})") do
      cmd  = 'lvcreate --thin'
      cmd += " --name #{new_resource.name}"
      cmd += " --virtualsize #{new_resource.size}"
      cmd += " #{new_resource.group}/#{new_resource.pool}"
      lvm_command(cmd)
    end
  end

  # -- 2. Optional LUKS encryption ----------------------------------------------
  if new_resource.encrypt_with_luks
    ensure_luks_open(lv_dev_path, new_resource.group, new_resource.name)
  end

  # -- 3. Optional filesystem creation -----------------------------------------
  dev = active_device_path(new_resource.group, new_resource.name)
  create_filesystem(new_resource.filesystem, dev, new_resource.filesystem_params)

  # -- 4. Optional mount point -------------------------------------------------
  setup_mount_point(new_resource.mount_point, dev, new_resource.filesystem)
end

# ----------------------------------------------------------------------------
# :resize
# ----------------------------------------------------------------------------

action :resize do
  raise 'lvm_thin_volume: group is required for :resize' if new_resource.group.nil?
  raise 'lvm_thin_volume: size is required for :resize'  if new_resource.size.nil?

  raise "Volume group '#{new_resource.group}' does not exist!" \
    unless current_vgs.key?(new_resource.group)
  raise "Thin volume '#{lv_key}' does not exist — cannot resize" unless lv_exists?

  size = new_resource.size

  # Thin volumes use virtualsize; compare against lv_size in bytes
  needs_resize =
    if LvmHelper.relative_size?(size.to_s)
      true
    else
      desired_bytes = LvmHelper.size_to_bytes(size.to_s)
      desired_bytes ? desired_bytes != lv_data['lv_size'].to_i : true
    end

  unless needs_resize
    Chef::Log.debug("Thin volume #{lv_key} virtual size is already #{size} — nothing to do")
    return
  end

  converge_by("Resize thin volume #{lv_key} to #{size}") do
    # lvresize with --virtualsize for thin volumes
    size_flag = LvmHelper.relative_size?(size.to_s) ? "-l #{size}" : "-L #{size}"
    lvm_command("lvresize --virtualsize #{size_flag} /dev/#{new_resource.group}/#{new_resource.name}")
  end

  # Grow the filesystem if one is configured
  if new_resource.filesystem
    dev = active_device_path(new_resource.group, new_resource.name)
    mp  = if new_resource.mount_point.is_a?(String)
            new_resource.mount_point
          else
            new_resource.mount_point&.fetch(:location, nil)
          end
    grow_filesystem(new_resource.filesystem, dev, mp)
  end
end
