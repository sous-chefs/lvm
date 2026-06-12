# frozen_string_literal: true
#
# test/fixtures/cookbooks/lvm_test/recipes/btrfs.rb
#
# Fixture recipe: LV with btrfs filesystem.
# NOTE: on RHEL 10 this requires kernel-modules-extra (Tech Preview).
# On Ubuntu 26.04 btrfs is fully supported.
#
# Validates: create btrfs, grow uses 'btrfs filesystem resize max <mountpoint>'
# NOT resize2fs or fsadm (which do not support btrfs).

lvm_physical_volume '/dev/sdb'

lvm_volume_group 'btrfsvg' do
  physical_volumes ['/dev/sdb']
end

lvm_logical_volume 'btrfslv' do
  group       'btrfsvg'
  size        '5G'
  filesystem  'btrfs'
  mount_point '/btrfsdata'
end
