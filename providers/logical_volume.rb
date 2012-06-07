require 'lvm'
action :create do
    device_name = "/dev/mapper/#{new_resource.group}-#{new_resource.name}"
    fs_type = new_resource[:filesystem]

    ruby_block "create_logical_volume_#{new_resource.name}" do
        block do 
            lvm = LVM::LVM.new

            name = new_resource.name
            group = new_resource.group
            size = case new_resource.size
                when /\d+[kKmMgGtT]/
                    "-L #{new_resource.size}"
                when /(\d{2}|100)%(FREE|VG)/
                    "-l #{new_resource.size}"
                when /(\d+) extents/
                    "-l #{$1}"
            end
            
            stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
            stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripesize}" : ''
            mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''
            contiguous = new_resource.contiguous ? "--contiguous y" : ''
            readahead = new_resource.readahead ? "--readahead #{new_resource.readahead}" : ''

            physical_volumes = new_resource.physical_volumes.join ' '
            
            command = "lvcreate #{size} #{stripes} #{stripe_size} #{mirrors} #{contiguous} #{readahead} --name #{name} #{physical_volumes} #{group}"

            Chef::Log.debug "Executing lvm command: #{command}"
            output = lvm.raw command 
            Chef::Log.debug "Command output: #{output}"
        end

        only_if do
            lvm = LVM::LVM.new
            vg = lvm.volume_groups[new_resource.group]
            return true if vg.nil?

            found_lvs = vg.logical_volumes.select do |lv|
                lv.name == new_resource.name
            end
            found_lvs.empty?
        end
        notifies :run, "execute[format_logical_volume_#{new_resource.name}]", :immediately
    end

    execute "format_logical_volume_#{new_resource.name}" do
        command "yes | mkfs -t #{fs_type} #{device_name}"
        action :nothing
        only_if { fs_type }
    end

    if new_resource[:mount_point]
        lv_mount_point = new_resource[:mount_point][:location]
        lv_mount_options = new_resource[:mount_point][:options]
        lv_mount_dump = new_resource[:mount_point][:dump]
        lv_mount_pass = new_resource[:mount_point][:pass]
        
        directory lv_mount_point do
            mode '0777'
            not_if "mount | grep #{device_name}"
        end

        mount "mount_logical_volume_#{new_resource.name}" do
            mount_point lv_mount_point
            options lv_mount_options
            dump lv_mount_dump
            pass lv_mount_pass
            device device_name
            fstype fs_type
            options lv_mount_options
            action [:mount, :enable]
        end
    end
end
