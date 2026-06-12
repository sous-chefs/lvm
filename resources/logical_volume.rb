# frozen_string_literal: true
#
# Cookbook:: lvm
# Resource:: logical_volume
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
# Creates, resizes, or manages an LVM logical volume.
# No gem dependencies — uses lvcreate/lvresize directly and
# `lvm lvs --reportformat json` for all idempotency checks.

unified_mode true

# Shared properties from partials
use 'partial/_lv_common'      # group, size, physical_volumes, wipe_signatures, ignore_skipped_cluster
use 'partial/_lv_filesystem'  # filesystem, filesystem_params, mount_point, encrypt_with_luks, luks_version, password

# ----------------------------------------------------------------------------
# Resource-specific properties
# ----------------------------------------------------------------------------

property :name, String, name_property: true,
                        description: 'Name of the logical volume'

property :take_up_free_space, [true, false], default: false,
                                             description: 'If true, uses 100%FREE; overrides size'

property :thin, [true, false], default: false,
                               description: 'Create as a thin logical volume provisioned from a thin pool'

property :pool, String,
         description: 'Name of the thin pool to provision from (requires thin: true)'

property :stripes, Integer,
         description: 'Number of stripes'

property :stripe_size, Integer,
         description: 'Stripe size in KB'

property :mirrors, Integer,
         description: 'Number of mirrors'

property :nosync, [true, false], default: false,
                                 description: 'Skip initial mirror synchronisation (--nosync)'

property :contiguous, [true, false], default: false,
                                     description: 'Require contiguous allocation (--contiguous y)'

property :readahead, [String, Integer],
         description: 'Read-ahead sector count (--readahead)'

property :lv_params, String, default: '',
                             description: 'Arbitrary extra flags appended verbatim to lvcreate'

# ----------------------------------------------------------------------------
# action_class helpers
# ----------------------------------------------------------------------------

action_class do
  include LvmActionHelpers

  def lv_key
    "#{new_resource.group}/#{new_resource.name}"
  end

  def lv_data
    current_lvs[lv_key]
  end

  def lv_exists?
    !lv_data.nil?
  end

  # Canonical /dev/<vg>/<lv> symlink path
  def lv_dev_path
    "/dev/#{new_resource.group}/#{new_resource.name}"
  end

  # Build the -L / -l flag for lvcreate / lvresize
  def size_flag(size_val = nil)
    return '-l 100%FREE' if new_resource.take_up_free_space

    s = size_val || new_resource.size
    raise "size is required for logical volume '#{new_resource.name}'" if s.nil?

    LvmHelper.relative_size?(s.to_s) ? "-l #{s}" : "-L #{s}"
  end

  def validate_create!
    raise 'lvm_logical_volume: group is required' if new_resource.group.nil?
    raise "Volume group '#{new_resource.group}' does not exist!" \
      unless current_vgs.key?(new_resource.group)

    validate_pvs_in_vg!(new_resource.physical_volumes, new_resource.group)

    if new_resource.mount_point.is_a?(Hash)
      loc = new_resource.mount_point[:location] || new_resource.mount_point['location']
      raise 'lvm_logical_volume: mount_point Hash must include :location' unless loc
    end

    unless new_resource.take_up_free_space || new_resource.thin || new_resource.size
      raise "lvm_logical_volume: 'size' must be provided for '#{new_resource.name}'"
    end

    # Pre-flight capacity check (absolute sizes only)
    return unless new_resource.size && !LvmHelper.relative_size?(new_resource.size.to_s)

    desired_bytes = LvmHelper.size_to_bytes(new_resource.size.to_s)
    return unless desired_bytes

    vg         = current_vgs[new_resource.group]
    free_bytes = vg['vg_extent_size'].to_i * vg['vg_free_count'].to_i
    return unless desired_bytes > free_bytes

    raise "Logical volume size (#{desired_bytes} bytes) exceeds available free space " \
          "in VG '#{new_resource.group}' (#{free_bytes} bytes)"
  end
end

# ----------------------------------------------------------------------------
# :create
# ----------------------------------------------------------------------------

action :create do
  validate_create!

  # -- 1. Create the LV --------------------------------------------------------
  unless lv_exists?
    converge_by("Create logical volume #{lv_key}") do
      if new_resource.thin
        cmd  = 'lvcreate --thin'
        cmd += " --name #{new_resource.name}"
        cmd += " --virtualsize #{new_resource.size}"
        cmd += " --thinpool #{new_resource.pool}"
        cmd += " #{new_resource.group}"
      else
        cmd  = 'lvcreate --zero=y'
        cmd += " #{size_flag}"
        cmd += " --name #{new_resource.name}"
        cmd += ' -W y'                                     if new_resource.wipe_signatures
        cmd += " -i #{new_resource.stripes}"               if new_resource.stripes
        cmd += " -I #{new_resource.stripe_size}"           if new_resource.stripe_size
        cmd += " -m #{new_resource.mirrors}"               if new_resource.mirrors
        cmd += ' --nosync'                                 if new_resource.mirrors && new_resource.nosync
        cmd += ' --contiguous y'                           if new_resource.contiguous
        cmd += " -r #{new_resource.readahead}"             if new_resource.readahead
        cmd += " #{new_resource.lv_params}"                unless new_resource.lv_params.to_s.empty?
        cmd += " #{new_resource.group}"
        cmd += " #{new_resource.physical_volumes.join(' ')}" if new_resource.physical_volumes
      end
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
  raise 'lvm_logical_volume: group is required for :resize'  if new_resource.group.nil?
  raise "lvm_logical_volume: 'size' is required for :resize" if new_resource.size.nil?
  raise "Volume group '#{new_resource.group}' does not exist!" \
    unless current_vgs.key?(new_resource.group)
  raise "Logical volume '#{lv_key}' does not exist — cannot resize" unless lv_exists?

  size = new_resource.size

  needs_resize =
    if LvmHelper.relative_size?(size.to_s)
      true
    else
      desired_bytes = LvmHelper.size_to_bytes(size.to_s)
      desired_bytes ? desired_bytes != lv_data['lv_size'].to_i : true
    end

  unless needs_resize
    Chef::Log.debug("Logical volume #{lv_key} is already #{size} — nothing to do")
    return
  end

  converge_by("Resize logical volume #{lv_key} to #{size}") do
    cmd  = "lvresize #{size_flag}"
    cmd += " /dev/#{new_resource.group}/#{new_resource.name}"
    cmd += " #{new_resource.physical_volumes.join(' ')}" if new_resource.physical_volumes
    lvm_command(cmd)
  end

  # Grow the filesystem to fill the newly extended LV
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
