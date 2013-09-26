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
    # The lvm_volume_group resource
    #
    class LvmVolumeGroup < Chef::Resource
      include Chef::DSL::Recipe

      # Logical volumes to be created in the volume group
      attr_reader :logical_volumes

      # Initializes the lvm_volume_group resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmVolumeGroup] the lvm_volume_group resource
      #
      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_volume_group
        @action = :create
        @allowed_actions.push :create
        @logical_volumes = []
        @provider = Chef::Provider::LvmVolumeGroup
      end

      # Attribute: name - name of the volume group
      #
      # @param arg [String] the name of the volume group
      #
      # @return [String] the name of the volume group
      #
      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => String,
          :name_attribute => true,
          :regex => /[\w+.-]+/,
          :required => true,
          :callbacks => {
            "cannot be '.' or '..'" => proc do |value|
              !(value == '.' || value == '..')
            end
          }
        )
      end

      # Attribute: physical_volumes - list of physical devices this volume group should be restricted to
      #
      # @param arg [Array, String] list of physical devices
      #
      # @return [String] list of physical devices
      #
      def physical_volumes(arg = nil)
        set_or_return(
          :physical_volumes,
          arg,
          :kind_of => [Array, String],
          :required => true
        )
      end

      # Attribute: physical_extent_size - the physical_extent_size
      #
      # @param arg [String] the physical extent size
      #
      # @return [String] the physical extent size
      #
      def physical_extent_size(arg = nil)
        set_or_return(
          :physical_extent_size,
          arg,
          :kind_of => String,
          :regex => /\d+[bBsSkKmMgGtTpPeE]?/
        )
      end

      # A shortcut for creating a logical volume when creating the volume group
      #
      # @param name [String] the name of the logical volume
      # @param block [Proc] the block defining the lvm_logical_volume resource
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
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
