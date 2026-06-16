# frozen_string_literal: true

provides :lvm_physical_volume
unified_mode true

default_action :create

property :volume_name,
          String,
          name_property: true,
          description: 'Device name of the physical volume (e.g. /dev/sdb)'

property :wipe_signatures,
          [true, false],
          default: false,
          description: 'Whether to wipe existing signatures before creating'

action :create do
  converge_if_changed do
    if pv_exists?(new_resource.volume_name)
      Chef::Log.info "Physical volume '#{new_resource.volume_name}' already exists. Skipping..."
    else
      yes_flag = new_resource.wipe_signatures ? '--yes' : ''
      lvm_raw("pvcreate #{yes_flag} #{new_resource.volume_name}".strip)
    end
  end
end

action :resize do
  converge_if_changed do
    if pv_exists?(new_resource.volume_name)
      lvm_raw("pvresize #{new_resource.volume_name}")
    else
      Chef::Log.info "Physical volume '#{new_resource.volume_name}' does not exist. Cannot resize."
    end
  end
end

action_class do
  include LVMCookbook

  def pv_exists?(device)
    !find_pv(device).nil?
  end
end
