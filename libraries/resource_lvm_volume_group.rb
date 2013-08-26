#
# Cookbook Name:: lvm
# Library:: resource_lvm_volume_group
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

require 'chef/resource'

class Chef
  class Resource
    class LvmVolumeGroup < Chef::Resource
      include Chef::DSL::Recipe

      attr_reader :logical_volumes

      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_volume_group
        @action = :create
        @allowed_actions.push :create
        @logical_volumes = []
        @provider = Chef::Provider::LvmVolumeGroup
      end

      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => String,
          :name_attribute => true,
          :regex => /[\w+.-]+/,
          :required => true,
          :callbacks => {
            "cannot be '.' or '..'" => Proc.new do |value|
              !(value == '.' || value == '..')
            end
          }
        )
      end

      def physical_volumes(arg = nil)
        set_or_return(
          :physical_volumes,
          arg,
          :kind_of => [Array, String],
          :required => true
        )
      end

      def physical_extent_size(arg = nil)
        set_or_return(
          :physical_extent_size,
          arg,
          :kind_of => String,
          :regex => /\d+[bBsSkKmMgGtTpPeE]?/
        )
      end

      def logical_volume(name, &block)
        Chef::Log.debug "Creating logical volume #{name}"
        volume = lvm_logical_volume(name, &block)
        volume.action :nothing
        @logical_volumes << volume
        volume
      end
    end
  end
end

