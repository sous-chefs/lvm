#
# Cookbook Name:: fake
# Recipe:: create
#
# Copyright (C) 2013 Opscode, Inc.
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

# Creates the loop back device
LvmTest::Helper.create_loop_devices(devices)

# Creates the physical device

log 'Creating physical volume for test'
devices.each do |device|
  lvm_physical_volume device
end

# Verify that the create action is idempotent
lvm_physical_volume devices.first

# Creates the volume group
#
lvm_volume_group 'vg-data' do
  physical_volumes ['/dev/loop0', '/dev/loop1', '/dev/loop2', '/dev/loop3']

  logical_volume 'logs' do
    size        '10M'
    filesystem  'ext2'
    mount_point :location => '/mnt/logs', :options => 'noatime,nodiratime'
    stripes     2
  end

  logical_volume 'home' do
    size        '5M'
    filesystem  'ext2'
    mount_point '/mnt/home'
    stripes     1
    mirrors     2
  end
end

lvm_volume_group 'vg-test' do
  physical_volumes ['/dev/loop4', '/dev/loop5', '/dev/loop6', '/dev/loop7']
end

# Creates the logical volume
#
lvm_logical_volume 'test' do
  group       'vg-test'
  size        '50%VG'
  filesystem  'ext3'
  mount_point '/mnt/test'
end

# Creates a small logical volume
#
lvm_logical_volume 'small' do
  group       'vg-test'
  size        '2%VG'
  filesystem  'ext3'
  mount_point '/mnt/small'
end
