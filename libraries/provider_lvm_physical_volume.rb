#
# Cookbook:: lvm
# Library:: provider_lvm_physical_volume
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

require 'chef/provider'
require 'chef/mixin/shell_out'
require 'chef/dsl/recipe'
require File.join(File.dirname(__FILE__), 'lvm')

class Chef
  class Provider
    # The provider for lvm_physical_volume resource
    #
    class LvmPhysicalVolume < Chef::Provider
      include Chef::DSL::Recipe
      include Chef::Mixin::ShellOut
      include LVMCookbook

      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmPhysicalVolume] the lvm_physical_volume resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmPhysicalVolume.new(@new_resource.name)
        @current_resource
      end

      # The create action
      #
      def action_create
        require_lvm_gems
        lvm = LVM::LVM.new
        yes_flag = new_resource.wipe_signatures == true ? '--yes' : ''
        if lvm.physical_volumes[new_resource.name].nil?
          Chef::Log.info "Creating physical volume '#{new_resource.name}'"
          lvm.raw "pvcreate #{new_resource.name} #{yes_flag}"
          new_resource.updated_by_last_action(true)
        else
          Chef::Log.info "Physical volume '#{new_resource.name}' found. Not creating..."
        end
      end

      def action_resize
        require_lvm_gems
        lvm = LVM::LVM.new
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
            Chef::Log.info "Resizing physical volume '#{new_resource.name}'"
            lvm.raw "pvresize #{new_resource.name}"
            # broadcast that we did a resize
            new_resource.updated_by_last_action true
          else
            Chef::Log.debug "Physical volume '#{new_resource.name}' is already the right size"
          end
        else
          Chef::Log.info "Physical volume '#{new_resource.name}' found. Not resizing..."
        end
      end
    end
  end
end
