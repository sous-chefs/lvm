# frozen_string_literal: true

provides :lvm_volume_group
unified_mode true

property :name, String,
         name_property: true,
         description: 'Name of the volume group',
         regex: /[\w+.-]+/,
         callbacks: {
           "cannot be '.' or '..'" => proc { |v| !%w(. ..).include?(v) },
         }

property :physical_volumes, [Array, String],
         required: true,
         description: 'Physical volume device(s) to include in the volume group'

property :physical_extent_size, String,
         description: 'Physical extent size (e.g. 4m, 8m)',
         regex: /\d+[bBsSkKmMgGtTpPeE]?/

property :wipe_signatures, [true, false],
         default: false,
         description: 'Whether to automatically wipe any preexisting signatures'

property :ignore_skipped_cluster, [true, false],
         default: false,
         description: 'Whether to pass --ignoreskippedcluster to LVM commands'

default_action :create

# DSL helpers for declaring logical volumes and thin pools inline.
# Resources are collected with :nothing action and triggered by the VG actions.
def logical_volumes
  @logical_volumes ||= []
end

def logical_volume(lv_name, &block)
  vol = declare_resource(:lvm_logical_volume, lv_name, &block)
  vol.action :nothing
  logical_volumes << vol
  vol
end

def thin_pool(tp_name, &block)
  vol = declare_resource(:lvm_thin_pool, tp_name, &block)
  vol.action :nothing
  logical_volumes << vol
  vol
end

action :create do
  pv_list = [new_resource.physical_volumes].flatten

  # Unmount any PVs that are currently mounted as filesystems.
  unmount_physical_volumes(pv_list)
  create_volume_group(pv_list)
  trigger_logical_volumes(:create)
end

action :extend do
  name    = new_resource.name
  pv_list = [new_resource.physical_volumes].flatten

  vg = lvm_volume_group(name, lvm_options)
  raise "Volume group '#{name}' is not a valid volume group" if vg.nil?

  vg_uuid    = vg[:uuid]
  pvs_to_add = []

  pv_list.each do |pv_name|
    pv = lvm_physical_volume(pv_name, lvm_options)
    pv_vg_uuid = pv.nil? ? '' : pv[:vg_uuid].to_s

    if pv_vg_uuid.empty?
      pvs_to_add << pv_name
    elsif pv_vg_uuid != vg_uuid
      raise "PV '#{pv_name}' already belongs to a different volume group. Cannot add to '#{name}'"
    end
    # pv_vg_uuid == vg_uuid means it's already in this VG — skip silently
  end

  unless pvs_to_add.empty?
    converge_by("extending volume group '#{name}' with #{pvs_to_add.join(', ')}") do
      lvm_raw("vgextend #{name} #{pvs_to_add.join(' ')}", lvm_options)
    end
    trigger_logical_volumes(:resize)
  end
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end

  def create_volume_group(pv_list)
    name = new_resource.name

    if lvm_volume_group(name, lvm_options)
      Chef::Log.info "Volume group '#{name}' already exists. Not creating..."
    else
      pe_flag  = new_resource.physical_extent_size ? "-s #{new_resource.physical_extent_size}" : ''
      yes_flag = new_resource.wipe_signatures ? '--yes' : '-qq'

      converge_by("creating volume group '#{name}'") do
        lvm_raw("vgcreate #{name} #{pe_flag} #{pv_list.join(' ')} #{yes_flag}", lvm_options)
      end
    end
  end

  # Trigger each collected LV/thin-pool sub-resource with the given action.
  # Sub-resources were declared with :nothing action so they only run when called here.
  def trigger_logical_volumes(action)
    new_resource.logical_volumes.each do |lv|
      lv.group new_resource.name
      lv.run_action(action)
    end
  end

  def unmount_physical_volumes(pv_list)
    pv_list.select { |pv| ::File.exist?(pv) }.each do |pv|
      mnt = get_mount_point(pv)
      next if mnt.nil?

      mount mnt do
        device pv
        action [:umount, :disable]
      end
    end
  end
end
