#
# Cookbook:: lvm
# Library:: resource_lvm_volume_group
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

require 'chef/resource'

class Chef
  class Resource
    # The lvm_volume_group resource
    #
    class LvmVolumeGroup < Chef::Resource
      resource_name :lvm_volume_group
      provides :lvm_volume_group

      default_action :create
      allowed_actions :create, :extend

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
        @logical_volumes = []
        @provider = Chef::Provider::LvmVolumeGroup
      end

      # property: name - name of the volume group
      property :name, String, name_property: true,
        regex: /[\w+.-]+/,
        required: true,
        callbacks: {
          "cannot be '.' or '..'" => proc do |value|
            !(value == '.' || value == '..')
          end,
        }

      # property: physical_volumes - list of physical devices this volume group should be restricted to
      property :physical_volumes, [Array, String], required: true

      # property: physical_extent_size - the physical_extent_size
      property :physical_extent_size, String, regex: /\d+[bBsSkKmMgGtTpPeE]?/

      # A shortcut for creating a logical volume when creating the volume group
      #
      # @param name [String] the name of the logical volume
      # @param block [Proc] the block defining the lvm_logical_volume resource
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def logical_volume(name, &block)
        Chef::Log.debug "Creating logical volume #{name}"
        volume = Chef::Resource::LvmLogicalVolume.new(name, &block)
        volume.action :nothing
        @logical_volumes << volume
        volume
      end

      # property: wipe_signature -
      property :wipe_signatures, [true, false], default: false

      # A shortcut for creating a thin pool (which is just a special type of logical volume) when creating the volume group
      #
      # @param name [String] the name of the thin pool
      # @param block [Proc] the block defining the lvm_thin_pool resource
      #
      # @return [Chef::Resource::LvmThinPool] the lvm_thin_pool resource
      #
      def thin_pool(name, &block)
        volume = Chef::Resource::LvmThinPool.new(name, &block)
        volume.action :nothing
        @logical_volumes << volume
        volume
      end

      # property: ignore_skipped_cluster -
      property :ignore_skipped_cluster, [TrueClass, FalseClass], default: false
    end
  end
end
