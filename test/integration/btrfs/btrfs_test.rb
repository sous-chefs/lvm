# frozen_string_literal: true
# InSpec controls: btrfs suite
# RHEL 10: requires kernel-modules-extra (Tech Preview, not for production)
# Ubuntu 26.04: fully supported, installer-selectable

control 'lvm-btrfs-lv-01' do
  impact 1.0
  title 'Logical volume btrfsvg/btrfslv exists'

  describe file('/dev/btrfsvg/btrfslv') do
    it { should be_block_device }
  end
end

control 'lvm-btrfs-fs-01' do
  impact 1.0
  title 'btrfs filesystem present on btrfslv'

  describe command('blkid /dev/mapper/btrfsvg-btrfslv') do
    its('stdout') { should match(/TYPE="btrfs"/) }
  end
end

control 'lvm-btrfs-mount-01' do
  impact 1.0
  title '/btrfsdata is mounted on btrfsvg/btrfslv'

  describe mount('/btrfsdata') do
    it { should be_mounted }
    its('device') { should match(%r{/dev/(mapper/btrfsvg-btrfslv|btrfsvg/btrfslv)}) }
    its('type')   { should eq 'btrfs' }
  end
end

control 'lvm-btrfs-grow-01' do
  impact 1.0
  title 'btrfs filesystem grow uses btrfs filesystem resize max (NOT fsadm/resize2fs)'
  # fsadm and lvresize --resizefs do NOT support btrfs.
  # The correct command is: btrfs filesystem resize max <mount_point>
  describe command('btrfs filesystem resize max /btrfsdata') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Resize .* is max/) }
  end
end
