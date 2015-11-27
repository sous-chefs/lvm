#
# Cookbook Name:: fake
# Recipe:: create
#
# Copyright (C) 2013 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distribued on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# The test device to use
devices = [
  '/dev/loop0',
  '/dev/loop1',
  '/dev/loop2',
  '/dev/loop3',
  '/dev/loop4',
  '/dev/loop5',
  '/dev/loop6',
  '/dev/loop7'
]

extend Chef::Mixin::ShellOut
# Creates the loop back device
LvmTest::Helper.create_loop_devices(devices) unless shell_out('pvs | grep -c /dev/loop1').stdout.to_i == 1

# Creates the physical device

log 'Creating physical volume for test'
devices.each do |device|
  lvm_physical_volume device do
    notifies :run, "script[note pv for #{device} created]", :immediately
  end
end

devices.each do |device|
  script "note pv for #{device} created" do
    interpreter 'bash'
    code "echo 'pv for #{device} has been created' >> /tmp/test_notifications"
    action :nothing
  end
end

# Verify that the create action is idempotent
lvm_physical_volume devices.first

# Creates the volume group
#
lvm_volume_group 'vg-data' do
  physical_volumes ['/dev/loop0', '/dev/loop1', '/dev/loop2', '/dev/loop3']
  notifies :run, 'script[note vg-data has been created]', :immediately

  logical_volume 'logs' do
    size '10M'
    filesystem 'ext2'
    mount_point location: '/mnt/logs', options: 'noatime,nodiratime'
    stripes 2
    notifies :run, 'script[note logs volume has been created]', :immediately
  end

  logical_volume 'home' do
    size '5M'
    filesystem 'ext2'
    mount_point '/mnt/home'
    stripes 1
    mirrors 2
    notifies :run, 'script[note home volume has been created]', :immediately
  end
end

script "note vg-data has been created" do
  interpreter 'bash'
  code "echo 'vg-data has been created' >> /tmp/test_notifications"
  action :nothing
end

script "note logs volume has been created" do
  interpreter 'bash'
  code "echo 'logs volume has been created' >> /tmp/test_notifications"
  action :nothing
end

script "note home volume has been created" do
  interpreter 'bash'
  code "echo 'home volume has been created' >> /tmp/test_notifications"
  action :nothing
end

lvm_volume_group 'vg-test' do
  physical_volumes ['/dev/loop4', '/dev/loop5', '/dev/loop6']
  notifies :run, 'script[note vg-test has been created]', :immediately
end

script "note vg-test has been created" do
  interpreter 'bash'
  code "echo 'vg-test has been created' >> /tmp/test_notifications"
  action :nothing
end

lvm_volume_group 'vg-test-extend' do
  action :extend
  name 'vg-test'
  physical_volumes ['/dev/loop4', '/dev/loop5', '/dev/loop6', '/dev/loop7']
  notifies :run, 'script[note vg-test has been extended]', :immediately
end

script 'note vg-test has been extended' do
  interpreter 'bash'
  code "echo 'vg-test has been extended' >> /tmp/test_notifications"
  action :nothing
end

# Creates the logical volume
#
lvm_logical_volume 'test' do
  group 'vg-test'
  size '50%VG'
  filesystem 'ext3'
  mount_point '/mnt/test'
  notifies :run, 'script[note test volume has been created]', :immediately
end

script 'note test volume has been created' do
  interpreter 'bash'
  code "echo 'test volume has been created' >> /tmp/test_notifications"
  action :nothing
end

# Creates a small logical volume
#
lvm_logical_volume 'small' do
  group 'vg-test'
  size '2%VG'
  filesystem 'ext3'
  mount_point '/mnt/small'
  notifies :run, 'script[note small volume has been created]', :immediately
end

script 'note small volume has been created' do
  interpreter 'bash'
  code "echo 'small volume has been created' >> /tmp/test_notifications"
  action :nothing
end

# Set the directory attributes of the mounted volume
#
directory '/mnt/small' do
  mode '0555'
  owner 1
  group 1
  only_if { File.stat('/mnt/small') != 0100555 }
end

# Creates a small logical volume
#
lvm_logical_volume 'small' do
  group 'vg-test'
  size '2%VG'
  filesystem 'ext3'
  mount_point '/mnt/small'
end
