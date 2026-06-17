# frozen_string_literal: true

provides :loop_devices
unified_mode true

property :devices, Array, name_property: true

# ioctl request code from <linux/loop.h>
LOOP_CTL_ADD = 0x4C80

action :create do
  Array(new_resource.devices).each do |device|
    next if shell_out('pvs').stdout.match?(device)

    num = device.slice(/\d+/).to_i
    backing_file = "/vfile#{num}"

    converge_by "create loop device #{device} backed by #{backing_file}" do
      # Create 128MB backing file
      shell_out!("dd if=/dev/zero of=#{backing_file} bs=2048 count=65536") unless ::File.exist?(backing_file)

      # Register loop device with the kernel via loop-control ioctl
      unless ::File.exist?(device)
        if ::File.exist?('/dev/loop-control')
          begin
            ::File.open('/dev/loop-control', 'r+') do |ctl|
              ctl.ioctl(LOOP_CTL_ADD, num)
            end
          rescue Errno::EEXIST
            Chef::Log.debug("Loop device #{num} already registered with kernel")
          end
        else
          shell_out!("mknod #{device} b 7 #{num}")
        end
      end

      # Detach if already attached, then reattach
      losetup_status = shell_out("losetup #{device}")
      if losetup_status.exitstatus == 0
        Chef::Log.info("#{device} is already attached, detaching first")
        shell_out!("losetup -d #{device}")
      end

      shell_out!("losetup #{device} #{backing_file}")
    end
  end
end
