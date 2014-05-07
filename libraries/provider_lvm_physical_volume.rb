#
# Cookbook Name:: lvm
# Library:: provider_lvm_physical_volume
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

require 'chef/provider'

class Chef
  class Provider
    # The provider for lvm_physical_volume resource
    #
    class LvmPhysicalVolume < Chef::Provider
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
      def action_resize
        require 'lvm'
        lvm = LVM::LVM.new
        pv = lvm.physical_volumes.select do |pvs|        
          pvs.name == new_resource.name 
        end
        unless pv.empty?
          # get the size the OS says the block device is
          block_device_size = shell_out("blockdev --getsize64 #{new_resource.name}").to_i
          # get the size LVM thinks the PV is
          pv_size = pv[0].dev_size.to_i
          
          # don't resize unless they are not same
          unless pv_size == block_device_size
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
