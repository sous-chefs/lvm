# frozen_string_literal: true
#
# test/fixtures/cookbooks/lvm_test/recipes/filesystem.rb
#
# Fixture recipe: LV with ext4 filesystem auto-mounted at /data.

lvm_physical_volume '/dev/sdb'

lvm_volume_group 'datavg' do
  physical_volumes ['/dev/sdb']
end

lvm_logical_volume 'datalv' do
  group      'datavg'
  size       '1G'
  filesystem 'ext4'
  mount_point(
    location: '/data',
    fstype: 'ext4',
    options: 'defaults,noatime'
  )
end
