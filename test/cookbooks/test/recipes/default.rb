# frozen_string_literal: true

#
# Cookbook:: test
# Recipe:: default
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

apt_update

package 'lvm2'

package 'thin-provisioning-tools' do
  only_if { platform_family?('debian') }
end

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

devices.each do |device|
  lvm_physical_volume device
end

# Verify that the create action is idempotent
lvm_physical_volume devices.first

# Creates the volume group with logical volumes
lvm_volume_group 'vg-data' do
  physical_volumes ['/dev/loop10', '/dev/loop11', '/dev/loop12', '/dev/loop13']

  logical_volume 'logs' do
    size '10M'
    filesystem 'ext2'
    mount_point location: '/mnt/logs', options: 'noatime,nodiratime'
    stripes 2
  end

  logical_volume 'home' do
    size '5M'
    filesystem 'ext2'
    mount_point '/mnt/home'
    stripes 1
    mirrors 2
  end
end
