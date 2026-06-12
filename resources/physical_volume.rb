# frozen_string_literal: true

provides :lvm_physical_volume
unified_mode true

property :volume_name,
         String,
         name_property: true

property :wipe_signatures,
         [true, false],
         default: false,
         description: 'Whether to automatically wipe any preexisting signatures'

property :ignore_skipped_cluster,
         [true, false],
         default: false,
         description: 'Whether to ignore skipped cluster VGs during LVM commands'

action :create do
  pv = lvm_physical_volume(new_resource.name, lvm_options)
  if pv.nil?
    yes_flag = new_resource.wipe_signatures ? '--yes' : '-qq'
    converge_by("creating physical volume '#{new_resource.name}'") do
      lvm_raw("pvcreate #{new_resource.name} #{yes_flag}", lvm_options)
    end
  end
end

action :resize do
  pv = lvm_physical_volume(new_resource.name, lvm_options)

  if pv.nil?
    Chef::Log.debug "Physical volume '#{new_resource.name}' not found. Not resizing..."
  else
    block_device_raw_size = pv[:dev_size]
    pv_size               = pv[:size]
    pe_size               = pv[:pe_count] > 0 ? pv_size / pv[:pe_count] : 0

    if pe_size > 0
      non_allocatable_space = block_device_raw_size % pe_size
      # LVM takes at least 1 full extent when the size is exactly divisible
      non_allocatable_space = pe_size if non_allocatable_space == 0

      block_device_allocatable_size = block_device_raw_size - non_allocatable_space

      if pv_size != block_device_allocatable_size
        converge_by("resizing physical volume '#{new_resource.name}'") do
          lvm_raw("pvresize #{new_resource.name}", lvm_options)
        end
      else
        Chef::Log.debug "Physical volume '#{new_resource.name}' already at full size. Not resizing..."
      end
    end
  end
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end
end
