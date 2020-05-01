#
# Cookbook:: test
# Recipe:: remove
#
# Copyright:: 2013-2019, Chef Software, Inc.
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

apt_update 'update'

include_recipe 'lvm'

# The test device to use
devices = [
  '/dev/loop10',
  '/dev/loop11',
  '/dev/loop12',
  '/dev/loop13',
]

loop_devices 'loop_devices' do
  devices devices
  action :create
end

# Creates the physical device

log 'Creating physical volume for test'
devices.each do |device|
  lvm_physical_volume device
end

# Verify that the create action is idempotent
lvm_physical_volume devices.first

# Creates the volume group
#
lvm_volume_group 'vg-rmdata' do
  physical_volumes ['/dev/loop10', '/dev/loop11', '/dev/loop12', '/dev/loop13']

  logical_volume 'rmlogs' do
    size '10M'
    filesystem 'ext2'
    mount_point location: '/mnt/rmlogs', options: 'noatime,nodiratime'
    stripes 2
  end

  logical_volume 'rmtest' do
    size '5M'
    filesystem 'ext4'
    mount_point '/mnt/rmtest'
    stripes 1
    mirrors 2
  end
end

# Removes a lvm_logical_volume
# Leaves the mount location/directory
#
lvm_logical_volume 'rmlogs' do
  group 'vg-rmdata'
  mount_point '/mnt/rmlogs'
  action :remove
end

# Removes a lvm_logical_volume
# Removes the mount location/directory
#
lvm_logical_volume 'rmtest' do
  group 'vg-rmdata'
  mount_point '/mnt/rmtest'
  remove_mount_point true
  action :remove
end
