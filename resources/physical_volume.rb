#
# Cookbook:: lvm
# Library:: resource_lvm_physical_volume
#
# Copyright:: 2009-2017, Chef Software, Inc.
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

property :volume_name, String, name_property: true

# whether to automatically wipe any preexisting signatures
property :wipe_signatures, [TrueClass, FalseClass], default: false

# whether to ignore skipped cluster VGs during LVM commands
property :ignore_skipped_cluster, [TrueClass, FalseClass], default: false

# The create action
#
action :create do
  require_lvm_gems
  lvm = LVM::LVM.new(lvm_options)
  if lvm.physical_volumes[new_resource.name].nil?
    yes_flag = new_resource.wipe_signatures == true ? '--yes' : ''

    converge_by("creating physical volume '#{new_resource.name}'") do
      lvm.raw "pvcreate #{new_resource.name} #{yes_flag}"
    end
  end
end

action :resize do
  require_lvm_gems
  lvm = LVM::LVM.new(lvm_options)
  pv = lvm.physical_volumes.select do |pvs|
    pvs.name == new_resource.name
  end
  if !pv.empty?
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

    # only resize if they are not same
    if pv_size != block_device_allocatable_size
      converge_by("Resizing physical volume '#{new_resource.name}'") do
        lvm.raw "pvresize #{new_resource.name}"
      end
    end
  else
    Chef::Log.debug "Physical volume '#{new_resource.name}' found. Not resizing..."
  end
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end
end
