# frozen_string_literal: true

provides :lvm_thin_pool_meta_data
unified_mode true

property :name, String,
         name_property: true,
         description: 'Name of the thin pool metadata logical volume'

property :group, String,
         required: true,
         description: 'Name of the volume group'

property :pool, String,
         required: true,
         description: 'Name of the thin pool whose metadata to resize'

property :size, String,
         required: true,
         description: 'New metadata size (e.g. 512M, 1G)',
         regex: /^(\d+[kKmMgGtT]|\d+)$/

default_action :resize

action :resize do
  group = new_resource.group
  pool  = new_resource.pool
  name  = new_resource.name

  vg = lvm_volume_group(group)
  raise "Error: volume group '#{group}' does not exist" if vg.nil?

  lvs = lvm_logical_volumes_for_vg(vg[:uuid])
  raise "Error: thin pool '#{pool}' does not exist in '#{group}'" if lvs.none? { |l| l[:name] == pool }

  pool_lv = lvs.find { |l| l[:metadata_lv] == "[#{name}]" }
  raise "Error: thin pool metadata volume '#{name}' does not exist in '#{group}'" if pool_lv.nil?

  pe_size          = vg[:extent_size]
  metadata_cur     = pool_lv[:metadata_size] / pe_size
  metadata_req     = parse_size_to_extents(new_resource.size, pe_size)

  if metadata_cur >= metadata_req
    Chef::Log.debug "Thin pool metadata '#{name}' in '#{group}' already at requested size"
  else
    converge_by("resizing thin pool metadata '#{name}' in '#{group}'") do
      lvm_raw("lvextend --poolmetadatasize #{new_resource.size} #{group}/#{pool}")
    end
  end
end

action_class do
  include LVMCookbook

  def parse_size_to_extents(size, pe_size)
    case size
    when /^(\d+)(k|K)$/ then (Regexp.last_match(1).to_i * 1_024) / pe_size
    when /^(\d+)(m|M)$/ then (Regexp.last_match(1).to_i * 1_048_576) / pe_size
    when /^(\d+)(g|G)$/ then (Regexp.last_match(1).to_i * 1_073_741_824) / pe_size
    when /^(\d+)(t|T)$/ then (Regexp.last_match(1).to_i * 1_099_511_627_776) / pe_size
    when /^(\d+)$/ then Regexp.last_match(1).to_i
    else raise "Invalid size '#{size}'"
    end
  end
end
