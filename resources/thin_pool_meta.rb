# frozen_string_literal: true
#
# Cookbook:: lvm
# Resource:: thin_pool_meta
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
# Manages the metadata volume of an existing LVM thin pool.
#
# Background
# ----------
# When LVM creates a thin pool it auto-creates two internal LVs:
#
#   [pool_tdata]   — the actual data area (what end users store things in)
#   [pool_tmeta]   — the metadata area (tracks block allocation for every
#                    thin volume provisioned from the pool)
#
# The metadata volume is typically sized at ~1% of pool size (min 2 MiB,
# max 16 GiB per LVM). As pools grow very large or host many thin volumes
# the default size can be too small, causing "thin pool ... out of space
# for metadata" errors and I/O pauses while LVM tries to recover.
#
# This resource lets you:
#   1. Extend the [pool_tmeta] volume if it is smaller than the desired size.
#   2. Control the pool metadata spare (a spare metadata copy LVM keeps in
#      the VG so it can recover from metadata corruption).
#
# Note on initial metadata sizing
# --------------------------------
# If you want to set the metadata size at pool *creation* time, use the
# `metadata_size` property on `lvm_thin_pool` instead. This resource is for
# post-creation growth only — LVM does not support shrinking pool metadata.
#
# Usage
# -----
#   lvm_thin_pool_meta 'thinpool' do
#     group   'datavg'
#     size    '1G'
#     persist true
#   end

unified_mode true

use 'partial/_lv_common' # group, physical_volumes, wipe_signatures, ignore_skipped_cluster
# _lv_filesystem is intentionally NOT included:
# metadata LVs never carry a filesystem or mount point.

# ----------------------------------------------------------------------------
# Properties
# ----------------------------------------------------------------------------

property :name, String, name_property: true,
                        description: 'Name of the thin pool whose metadata volume to manage ' \
                      '(matches the lvm_thin_pool resource name)'

property :size, [String, Integer], required: true,
                                   coerce: proc { |v| v.is_a?(Integer) ? "#{v}b" : v },
                                   description: 'Target size for the thin pool metadata volume ' \
                      '(e.g. "512M", "1G", 1073741824). ' \
                      'LVM does not support shrinking pool metadata — only growth is applied.'

property :persist, [true, false], default: true,
                                  description: 'Enable the LVM pool metadata spare volume ' \
                      '(lvchange --poolmetadataspare y/n <vg>). ' \
                      'The spare is a standby metadata copy LVM uses if the active ' \
                      'metadata volume is damaged. Strongly recommended in production.'

property :contiguous, [true, false], default: false,
                                     description: 'Require contiguous allocation for the metadata extension (--contiguous y)'

property :readahead, [String, Integer], default: 'auto',
                                        description: 'Read-ahead sector count for the metadata volume (--readahead)'

property :stripes, Integer,
         description: 'Number of stripes for the metadata extension'

property :stripe_size, Integer,
         description: 'Stripe size in KB for the metadata extension'

# ----------------------------------------------------------------------------
# action_class helpers
# ----------------------------------------------------------------------------

action_class do
  include LvmActionHelpers

  def pool_key
    "#{new_resource.group}/#{new_resource.name}"
  end

  # Query the size (in bytes) of the pool's internal metadata volume via
  # `lvs --all`, which includes hidden/internal LVs shown with brackets.
  #
  # LVM names the internal metadata LV "[<pool>_tmeta]".
  # Returns nil if not found (pool does not exist yet).
  def current_meta_size_bytes
    cmd = shell_out(
      "lvs --noheadings --all --units b --nosuffix -o lv_name,lv_size #{new_resource.group}",
      env: { 'LVM_SUPPRESS_FD_WARNINGS' => '1' }
    )
    return unless cmd.exitstatus.zero?

    target = "[#{new_resource.name}_tmeta]"
    cmd.stdout.split("\n").each do |line|
      parts = line.strip.split(/\s+/)
      return parts[1].to_i if parts.first == target
    end
    nil
  end

  def desired_size_bytes
    LvmHelper.size_to_bytes(new_resource.size.to_s)
  end

  def needs_extend?
    current = current_meta_size_bytes
    return true if current.nil?

    desired = desired_size_bytes
    return false if desired.nil? # can't compare a relative spec — pass through to lvextend

    desired > current
  end

  def build_extend_command
    size = new_resource.size
    # lvextend --poolmetadatasize takes an absolute size (no + prefix needed
    # here since we already guard that desired > current above).
    size_arg = LvmHelper.relative_size?(size.to_s) ? "-l #{size}" : "-L #{size}"

    cmd  = "lvextend --poolmetadatasize #{size_arg}"
    cmd += " --stripes #{new_resource.stripes}" if new_resource.stripes
    cmd += " --stripesize #{new_resource.stripe_size}" if new_resource.stripe_size
    cmd += ' --contiguous y'                        if new_resource.contiguous
    cmd += " --readahead #{new_resource.readahead}" if new_resource.readahead && new_resource.readahead != 'auto'
    cmd += " #{new_resource.group}/#{new_resource.name}"
    cmd += " #{new_resource.physical_volumes.join(' ')}" \
      if new_resource.physical_volumes && !new_resource.physical_volumes.empty?
    cmd
  end
end

# ----------------------------------------------------------------------------
# :create — grow metadata volume to at least `size`; set spare preference
# ----------------------------------------------------------------------------

action :create do
  raise 'lvm_thin_pool_meta: group is required' if new_resource.group.nil?
  raise "Volume group '#{new_resource.group}' does not exist!" \
    unless current_vgs.key?(new_resource.group)
  raise "Thin pool '#{pool_key}' does not exist! " \
        "Create lvm_thin_pool '#{new_resource.name}' first." \
    unless current_lvs.key?(pool_key)

  # -- 1. Extend metadata volume if it is smaller than desired -----------------
  if needs_extend?
    converge_by("Extend thin pool metadata for #{pool_key} to #{new_resource.size}") do
      lvm_command(build_extend_command)
    end
  else
    current = current_meta_size_bytes
    Chef::Log.debug("Thin pool #{pool_key} metadata is already #{current} bytes — no extension needed")
  end

  # -- 2. Pool metadata spare --------------------------------------------------
  # lvchange --poolmetadataspare manages a VG-level spare metadata LV that LVM
  # uses to repair a corrupted thin pool metadata volume.
  spare_state = new_resource.persist ? 'y' : 'n'
  converge_by("Set poolmetadataspare #{spare_state} on VG '#{new_resource.group}'") do
    lvm_command("lvchange --poolmetadataspare #{spare_state} #{new_resource.group}")
  end
end

# ----------------------------------------------------------------------------
# :resize — explicit alias for :create (same logic, kept for API consistency)
# ----------------------------------------------------------------------------

action :resize do
  run_action(:create)
end
