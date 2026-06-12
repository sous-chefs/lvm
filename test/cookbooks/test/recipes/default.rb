# frozen_string_literal: true
#
# Test cookbook default recipe.
# Uses loopback devices to exercise lvm resources without real disks.
# Uses losetup --find to avoid conflicts with loop devices used by snap on Ubuntu.

package 'lvm2'
package 'thin-provisioning-tools' if platform_family?('debian')

# Create backing image files and attach them to the next available loop devices.
# Saves discovered device paths to /tmp for lazy reading by subsequent resources.
bash 'setup lvm test loop devices' do
  code <<~SH
    set -e
    [ -f /tmp/lvm-test-pv1.img ] || dd if=/dev/zero of=/tmp/lvm-test-pv1.img bs=1M count=64
    [ -f /tmp/lvm-test-pv2.img ] || dd if=/dev/zero of=/tmp/lvm-test-pv2.img bs=1M count=64
    losetup -j /tmp/lvm-test-pv1.img | grep -q . || losetup $(losetup -f) /tmp/lvm-test-pv1.img
    losetup -j /tmp/lvm-test-pv2.img | grep -q . || losetup $(losetup -f) /tmp/lvm-test-pv2.img
    losetup -j /tmp/lvm-test-pv1.img | cut -d: -f1 > /tmp/lvm-test-pv1.dev
    losetup -j /tmp/lvm-test-pv2.img | cut -d: -f1 > /tmp/lvm-test-pv2.dev
  SH
  not_if do
    ::File.exist?('/tmp/lvm-test-pv1.dev') &&
      system('losetup $(cat /tmp/lvm-test-pv1.dev) > /dev/null 2>&1')
  end
end

# Create physical volumes on the discovered loop devices.
# lvm_physical_volume is tested here; device paths are read lazily at converge time.
ruby_block 'create lvm test physical volumes' do
  block do
    ['/tmp/lvm-test-pv1.dev', '/tmp/lvm-test-pv2.dev'].each do |dev_file|
      dev = ::File.read(dev_file).strip
      r = declare_resource(:lvm_physical_volume, dev)
      r.wipe_signatures true
      r.run_action(:create)
    end
  end
end

# Create VG with an inline LV — physical_volumes resolved lazily after loop setup.
lvm_volume_group 'vg_test' do
  physical_volumes lazy {
    [
      ::File.read('/tmp/lvm-test-pv1.dev').strip,
      ::File.read('/tmp/lvm-test-pv2.dev').strip,
    ]
  }

  logical_volume 'lv_data' do
    size '10M'
    filesystem 'ext4'
    mount_point '/mnt/lvm-test'
  end
end
