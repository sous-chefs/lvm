require 'lvm'

attr_reader :lvm

def initialize *args
    super
    @lvm = LVM::LVM.new
end

action :create do
    ruby_block "create_volume_group_#{new_resource.name}" do
        block do
            name = new_resource.name
            physical_volumes = new_resource.physical_volumes.join ' '
            physical_extent_size = new_resource.physical_extent_size ? "-s #{new_resource.physical_extent_size}" : ''
            command = "vgcreate #{name} #{physical_extent_size} #{physical_volumes}"
            
            Chef::Log.debug "Executing lvm command '#{command}'"
            output = lvm.raw command
            Chef::Log.debug "Command output: '#{output}'"
            new_resource.updated_by_last_action = true
        end
        not_if { lvm.volume_groups[new_resource.name] }
        notifies :create, "ruby_block[create_logical_volumes_for_group_#{new_resource.name}]", :immediately
    end

    ruby_block "create_logical_volumes_for_group_#{new_resource.name}" do
        block do 
            new_resource.logical_volumes.each do |lv|
                lv.group = new_resource.name
                lv.run_action :create
            end
        end
    end
end
