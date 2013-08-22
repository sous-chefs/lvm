#
# Cookbook Name:: lvm-test
# Recipe:: create
#
# Copyright (C) 2013 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# The test device to use
device = '/dev/loop0'

# Creates the loop back device
LvmTest::Helper.create_loop_devices(device)

# Creates the physical device
#
lvm_physical_volume device

# Creates the volume group
#
lvm_volume_group 'vg-data' do
  physical_volumes device
end

# Creates the logical volume
#
lvm_logical_volume 'test' do
  group 'vg-data'
  size '90%VG'
  filesystem 'ext4'
  mount_point '/mnt/test'
end
