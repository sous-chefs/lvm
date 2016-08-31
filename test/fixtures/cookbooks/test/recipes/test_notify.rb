
## this recipe is purely used in chefspec to verify you can test notifications

file '/tmp/test_notify'

lvm_physical_volume '/dev/test_notify_pv' do
  notifies :create, 'file[/tmp/test_notify]', :immediately
end

lvm_volume_group 'notify_vg' do
  notifies :create, 'file[/tmp/test_notify]', :immediately
end

lvm_logical_volume 'test_notify_lv' do
  group 'notify_vg'
  size '2%VG'
  filesystem 'ext4'
  notifies :create, 'file[/tmp/test_notify]', :immediately
end
