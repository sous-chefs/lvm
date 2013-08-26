#
# Cookbook Name:: lvm
# Recipe:: default
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
    class LvmPhysicalVolume < Chef::Provider
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmPhysicalVolume.new(@new_resource.name)
        @current_resource
      end

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
    end
  end
end
