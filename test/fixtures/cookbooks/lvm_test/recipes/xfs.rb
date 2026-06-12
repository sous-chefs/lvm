# frozen_string_literal: true
#
# test/fixtures/cookbooks/lvm_test/recipes/xfs.rb
#
# Fixture recipe: LV with XFS filesystem — RHEL 10 default.
# Validates: create XFS, xfs_growfs uses mount point (not device path).

lvm_physical_volume '/dev/sdb'

lvm_volume_group 'xfsvg' do
  physical_volumes ['/dev/sdb']
end

lvm_logical_volume 'xfslv' do
  group       'xfsvg'
  size        '5G'
  filesystem  'xfs'
  mount_point '/xfsdata'
end
