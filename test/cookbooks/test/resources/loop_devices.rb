# frozen_string_literal: true

provides :loop_devices
unified_mode true

property :devices, Array, name_property: true

action :create do
  Array(new_resource.devices).each do |device|
    next if shell_out!('pvs').stdout.match?(device)

    num = device.slice(/\d+/)
    backing_file = "/vfile#{num}"

    converge_by "create loop device #{device} backed by #{backing_file}" do
      shell_out!("dd if=/dev/zero of=#{backing_file} bs=2048 count=65536") unless ::File.exist?(backing_file)

      unless ::File.exist?(device)
        Chef::Log.info("#{device} device node missing, creating with mknod")
        shell_out!("mknod #{device} b 7 #{num}")
      end

      losetup_status = shell_out("losetup #{device}")
      if losetup_status.exitstatus == 0
        Chef::Log.info("#{device} is already attached, detaching first")
        shell_out!("losetup -d #{device}")
      end

      shell_out!("losetup #{device} #{backing_file}")
    end
  end
end
