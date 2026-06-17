# frozen_string_literal: true

provides :lvm_volume_group
unified_mode true

default_action :create

property :vg_name,
          String,
          name_property: true,
          description: 'Name of the volume group'

property :physical_volumes,
          [String, Array],
          required: true,
          coerce: proc { |val| Array(val) },
          description: 'Physical volume(s) to use for the volume group'

property :physical_extent_size,
          String,
          regex: /^\d+[kKmMgGtT]?$/,
          description: 'Physical extent size (e.g. 4M)'

property :wipe_signatures,
          [true, false],
          default: false,
          description: 'Whether to automatically wipe signatures on new PVs'

property :ignore_skipped_cluster,
          [true, false],
          default: false,
          description: 'Whether to ignore skipped cluster VGs during LVM commands'

# Nested logical volumes declared via the DSL
attr_reader :logical_volumes

def after_created
  @logical_volumes ||= []
  super
end

# DSL method for declaring nested logical volumes within a volume group
def logical_volume(name, &block)
  @logical_volumes ||= []
  volume = declare_resource(:lvm_logical_volume, name, created_at: caller.first, &block)
  volume.action :nothing
  @logical_volumes << volume
  volume
end

# DSL method for declaring nested thin pools within a volume group
def thin_pool(name, &block)
  @logical_volumes ||= []
  volume = declare_resource(:lvm_thin_pool, name, created_at: caller.first, &block)
  volume.action :nothing
  @logical_volumes << volume
  volume
end

action :create do
  # Ensure all physical volumes exist
  new_resource.physical_volumes.each do |pv|
    lvm_physical_volume pv do
      wipe_signatures new_resource.wipe_signatures
    end
  end

  vg = find_vg(new_resource.vg_name)
  if vg.nil?
    converge_by("create volume group #{new_resource.vg_name}") do
      pe_size = new_resource.physical_extent_size ? "-s #{new_resource.physical_extent_size}" : ''
      pvs = new_resource.physical_volumes.join(' ')
      lvm_raw("vgcreate #{pe_size} #{new_resource.vg_name} #{pvs}".strip)
    end
  else
    Chef::Log.info "Volume group '#{new_resource.vg_name}' already exists. Skipping create..."
  end

  # Process nested logical volumes
  process_logical_volumes(:create)
end

action :extend do
  vg = find_vg(new_resource.vg_name)
  raise "Volume group '#{new_resource.vg_name}' does not exist" if vg.nil?

  current_pvs = list_pvs_in_vg(new_resource.vg_name).map { |pv| pv['pv_name'] }

  new_resource.physical_volumes.each do |pv|
    next if current_pvs.include?(pv)

    # Create the PV if it doesn't exist
    lvm_physical_volume pv do
      wipe_signatures new_resource.wipe_signatures
    end

    # Extend the VG
    converge_by("extend volume group #{new_resource.vg_name} with #{pv}") do
      lvm_raw("vgextend #{new_resource.vg_name} #{pv}")
    end
  end

  # Process nested logical volumes
  process_logical_volumes(:create)
end

action_class do
  include LVMCookbook

  def process_logical_volumes(action)
    new_resource.logical_volumes&.each do |lv|
      lv.group new_resource.vg_name
      lv.run_action action
      new_resource.updated_by_last_action(true) if lv.updated?
    end
  end
end
