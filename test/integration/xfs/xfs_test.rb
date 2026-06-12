# frozen_string_literal: true
# InSpec controls: xfs suite — RHEL 10 default filesystem

control 'lvm-xfs-lv-01' do
  impact 1.0
  title 'Logical volume xfsvg/xfslv exists'

  describe file('/dev/xfsvg/xfslv') do
    it { should be_block_device }
  end
end

control 'lvm-xfs-fs-01' do
  impact 1.0
  title 'XFS filesystem present on xfslv'

  describe command('blkid /dev/mapper/xfsvg-xfslv') do
    its('stdout') { should match(/TYPE="xfs"/) }
  end
end

control 'lvm-xfs-mount-01' do
  impact 1.0
  title '/xfsdata is mounted on xfsvg/xfslv'

  describe mount('/xfsdata') do
    it { should be_mounted }
    its('device') { should match(%r{/dev/(mapper/xfsvg-xfslv|xfsvg/xfslv)}) }
    its('type')   { should eq 'xfs' }
  end
end

control 'lvm-xfs-grow-01' do
  impact 1.0
  title 'XFS filesystem can be grown with xfs_growfs (requires mount point)'
  # xfs_growfs takes a mount point, NOT a device path
  # This control documents the expected grow command for CI verification
  describe command('xfs_growfs /xfsdata') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/data blocks changed/) }
  end
end
