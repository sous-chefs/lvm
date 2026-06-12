# frozen_string_literal: true
#
# test/fixtures/cookbooks/lvm_test/recipes/default.rb
#
# Fixture recipe: basic PV → VG → LV stack (no filesystem, no LUKS).
# Uses /dev/sdb — the second disk attached by the Vagrant driver.

# Create a physical volume on the spare disk
lvm_physical_volume '/dev/sdb'

# Create a volume group from that PV
lvm_volume_group 'datavg' do
  physical_volumes ['/dev/sdb']
end

# Create a 500 MiB logical volume (no filesystem yet)
lvm_logical_volume 'datalv' do
  group 'datavg'
  size  '500M'
end
