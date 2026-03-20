# frozen_string_literal: true

provides :lvm_thin_pool_meta_data
unified_mode true

default_action :resize

property :lv_name,
          String,
          name_property: true,
          description: 'Name of the thin pool metadata logical volume'

property :group,
          String,
          description: 'Volume group name the logical volume belongs to'

property :pool,
          String,
          required: true,
          description: 'Name of the thin pool logical volume in which this metadata volume exists'

property :size,
          String,
          required: true,
          regex: /^(\d+[kKmMgGtT]|\d+)$/,
          description: 'Size of thin pool metadata logical volume'

property :lv_params,
          String,
          description: 'Additional parameters for lvextend'

property :filesystem,
          String,
          description: 'File system type'

property :filesystem_params,
          String,
          description: 'Additional parameters for mkfs'

property :mount_point,
          [String, Hash],
          description: 'Mount point (unused for metadata, kept for interface compatibility)'

property :ignore_skipped_cluster,
          [true, false],
          default: false,
          description: 'Whether to ignore skipped cluster VGs during LVM commands'

action :resize do
  require_lvm_gems
  lvm = LVM::LVM.new
  name = new_resource.lv_name
  group = new_resource.group
  pool = new_resource.pool
  vg = lvm.volume_groups[group]

  # if doing a resize make sure that the volume exists before doing anything
  raise("Error volume group #{group} does not exist") if vg.nil?

  lv = vg.logical_volumes.select do |lvs|
    lvs.name == pool
  end

  # make sure that the thin pool / volume specified exists in the VG specified.
  raise("Error logical volume (thin pool) #{pool} does not exist") if lv.empty?

  lv_metadata = vg.logical_volumes.select do |lvs|
    lvs.metadata_lv == "[#{name}]"
  end

  # make sure that the thin pool metadata specified exists in the VG specified
  raise("Error logical volume thin pool metadata volume #{name} does not exist") if lv_metadata.empty?

  lv_metadata = lv_metadata.first
  pe_size = vg.extent_size.to_i
  lv_metadata_size_cur = lv_metadata.metadata_size.to_i / pe_size

  lv_metadata_size = new_resource.size
  lv_metadata_size_req = case lv_metadata_size
                         when /^(\d+)(k|K)$/
                           (Regexp.last_match[1].to_i * 1024) / pe_size
                         when /^(\d+)(m|M)$/
                           (Regexp.last_match[1].to_i * 1_048_576) / pe_size
                         when /^(\d+)(g|G)$/
                           (Regexp.last_match[1].to_i * 1_073_741_824) / pe_size
                         when /^(\d+)(t|T)$/
                           (Regexp.last_match[1].to_i * 1_099_511_627_776) / pe_size
                         when /^(\d+)$/
                           Regexp.last_match[1].to_i
                         else
                           raise("Invalid size #{Regexp.last_match[1]} for lvm resize")
                         end

  if lv_metadata_size_cur >= lv_metadata_size_req
    Chef::Log.debug "Logical volume thin pool metadata #{lv_metadata.name} in volume group #{group} already at requested size"
  else
    command = resize_command(new_resource.size)
    Chef::Log.debug "Running command: #{command}"
    output = lvm.raw command
    Chef::Log.debug "Command output: #{output}"
    # broadcast that we did a resize
    new_resource.updated_by_last_action true
  end
end

action_class do
  include LVMCookbook

  def resize_command(lv_size_req)
    group = new_resource.group
    pool = new_resource.pool
    "lvextend --poolmetadatasize #{lv_size_req} #{group}/#{pool}"
  end
end
