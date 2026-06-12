# frozen_string_literal: true
#
# test/fixtures/cookbooks/lvm_test/recipes/thin.rb
#
# Fixture: thin pool + lvm_thin_volume + lvm_thin_pool_meta
# Demonstrates the full thin provisioning stack:
#   PV → VG → thin pool → thin volume + metadata management

lvm_physical_volume '/dev/sdb'

lvm_volume_group 'thinvg' do
  physical_volumes ['/dev/sdb']
end

lvm_thin_pool 'thinpool' do
  group 'thinvg'
  size  '10G'
end

# Grow pool metadata volume to 256M (larger than LVM default auto-size for
# small pools) and ensure the metadata spare is enabled.
lvm_thin_pool_meta 'thinpool' do
  group   'thinvg'
  size    '256M'
  persist true
end

lvm_thin_volume 'thinlv' do
  group 'thinvg'
  pool  'thinpool'
  size  '50G'
end
