def initialize *args
    super
    require 'lvm'
end

action :create do
    ruby_block "create physical volume on #{new_resource.name}" do
        @lvm = LVM::LVM.new
        block do
            @lvm.raw "pvcreate #{new_resource.name}"
        end
        only_if { @lvm.physical_volumes[new_resource.name].nil? }
    end
end

action :resize do
    ruby_block "resize physical volume on #{new_resource.name}" do
      @lvm = LVM::LVM.new
      block do
        @lvm.raw "pvresize #{new_resource.name}"
      end
      not_if @lvm.physical_volumes[new_resource.name].nil?
    end
end
