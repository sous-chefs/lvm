#
# Cookbook Name:: test
# Recipe:: create
#
# Copyright (C) 2013-2016 Chef Software, Inc.
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

include_recipe 'lvm'

execute 'extend loop0 device' do
  command <<-EOF
dd if=/dev/zero bs=512 count=65536 >> /vfile0
losetup -c /dev/loop0
touch /vfile0.extended
EOF
  not_if { File.exist?('/vfile0.extended') }
end

lvm_physical_volume 'loop0_resize' do
  name '/dev/loop0'
  action :resize
end

# Create a LV to resize
#
lvm_logical_volume 'small_resize' do
  action :create
  group 'vg-test'
  size '8M'
  filesystem 'ext3'
  mount_point '/mnt/small_resize'
end

# Resize a lv based off explicit size
#
lvm_logical_volume 'small_resize_test' do
  action :resize
  name 'small_resize'
  group 'vg-test'
  size '16M'
  filesystem 'ext3'
  mount_point '/mnt/small_resize'
end

# Create a LV to resize
#
lvm_logical_volume 'percent_resize' do
  action :create
  group 'vg-test'
  size '5%VG'
  filesystem 'ext3'
  mount_point '/mnt/percent_resize'
end

# Resize a lv based off percent
#
lvm_logical_volume 'percent_resize_test' do
  action :resize
  name 'percent_resize'
  group 'vg-test'
  size '10%VG'
  filesystem 'ext3'
  mount_point '/mnt/percent_resize'
end

# Create a LV to resize
#
lvm_logical_volume 'small_noresize' do
  action :create
  group 'vg-test'
  size '8M'
  filesystem 'ext3'
  mount_point '/mnt/small_noresize'
end

# Resize a lv based off explicit size
# Should stay the same size
#
lvm_logical_volume 'small_noresize_test' do
  action :resize
  name 'small_noresize'
  group 'vg-test'
  size '8M'
  filesystem 'ext3'
  mount_point '/mnt/small_noresize'
end

# Create a LV to resize
#
lvm_logical_volume 'percent_noresize' do
  action :create
  group 'vg-test'
  size '5%VG'
  filesystem 'ext3'
  mount_point '/mnt/percent_noresize'
end

# Resize a lv based off percent
# Should stay the same size
#
lvm_logical_volume 'percent_noresize_test' do
  action :resize
  name 'percent_noresize'
  group 'vg-test'
  size '5%VG'
  filesystem 'ext3'
  mount_point '/mnt/percent_noresize'
end

# Resize a lv based off percent
# Should stay the same size
#
lvm_logical_volume 'remainder_resize' do
  action [:create, :resize]
  name 'remainder_resize'
  group 'vg-test'
  size '1'
  filesystem 'ext3'
  take_up_free_space true
  mount_point '/mnt/remainder_resize'
end
