#
# Cookbook:: test
# Recipe:: create_thin
#
# Copyright:: 2016-2017, Ontario Systems, LLC
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

devices = [
  '/dev/loop0',
  '/dev/loop1',
  '/dev/loop2',
  '/dev/loop3',
]

loop_devices 'loop_devices' do
  devices devices
  action :create
end

log 'Creating physical volume for test'
devices.each do |device|
  lvm_physical_volume device
end

# create a volume group and use the shortcut methods for creating a thin pool and thin volumes to test that they work
lvm_volume_group 'vg-data' do
  physical_volumes ['/dev/loop0', '/dev/loop1']

  thin_pool 'tpool' do
    size '24M'

    thin_volume 'tvol01' do
      filesystem 'ext2'
      mount_point '/mnt/tvol01'
      size '40M'
    end

    # a thin volume that's larger than the pool
    thin_volume 'tvol02' do
      filesystem 'ext2'
      mount_point '/mnt/tvol02'
      size '1G'
    end
  end
end

lvm_volume_group 'vg-test' do
  physical_volumes ['/dev/loop2', '/dev/loop3']
end

lvm_thin_pool 'lv-thin' do
  group 'vg-test'
  size '10%VG'
end

lvm_thin_volume 'thin_vol_1' do
  group 'vg-test'
  pool 'lv-thin'
  size '16M'
  filesystem 'ext3'
  mount_point '/mnt/thin1'
end
