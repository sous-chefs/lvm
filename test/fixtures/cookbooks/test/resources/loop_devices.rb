provides :loop_devices

property :devices, Array, name_property: true

action :create do
  Array(new_resource.devices).each do |device|
    next if shell_out!('pvs').stdout.match?(device)
    converge_if_changed do
      num = device.slice(/\d+/)
      shell_out!("dd if=/dev/zero of=/vfile#{num} bs=2048 count=65536")
      shell_out!("losetup #{device} /vfile#{num}")
    end
  end
end
