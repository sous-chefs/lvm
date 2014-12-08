#
# Cookbook Name:: lvm
# Provider:: physical_volume
#
# Copyright 2009-2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Chef::Mixin::ShellOut

action :create do
  require 'lvm'
  lvm = LVM::LVM.new
  if lvm.physical_volumes[new_resource.name].nil?
    Chef::Log.info "Creating physical volume '#{new_resource.name}'"
    lvm.raw "pvcreate #{new_resource.name}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Physical volume '#{new_resource.name}' found. Not creating..."
  end
end

action :resize do
  require 'lvm'
  lvm = LVM::LVM.new
  pv = lvm.physical_volumes.select do |pvs|
    pvs.name == new_resource.name
  end
  if pv.empty?
    Chef::Log.info "Physical volume '#{new_resource.name}' found. Not resizing..."
  else
    # get the size the OS says the block device is
    block_device_raw_size = pv[0].dev_size.to_i
    # get the size LVM thinks the PV is
    pv_size = pv[0].size.to_i
    pe_size = pv_size / pv[0].pe_count

    # get the amount of space that cannot be allocated
    non_allocatable_space = block_device_raw_size % pe_size
    # if it's an exact amount LVM appears to just take 1 full extent
    non_allocatable_space = pe_size if non_allocatable_space == 0

    block_device_allocatable_size = block_device_raw_size - non_allocatable_space

    # don't resize unless they are not same
    if pv_size == block_device_allocatable_size
      Chef::Log.debug "Physical volume '#{new_resource.name}' is already the right size"
    else
      Chef::Log.info "Resizing physical volume '#{new_resource.name}'"
      lvm.raw "pvresize #{new_resource.name}"
      # broadcast that we did a resize
      new_resource.updated_by_last_action true
    end
  end
end
