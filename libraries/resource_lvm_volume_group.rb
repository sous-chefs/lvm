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
      include Chef::DSL::Recipe

      provides :lvm_volume_group

      unified_mode true if respond_to?(:unified_mode)

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
          kind_of: String,
          name_attribute: true,
          regex: /[\w+.-]+/,
          required: true,
          callbacks: {
            "cannot be '.' or '..'" => proc do |value|
              !(value == '.' || value == '..')
            end,
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
          kind_of: [Array, String],
          required: true
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
          kind_of: String,
          regex: /\d+[bBsSkKmMgGtTpPeE]?/
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

      # Attribute: wipe_signature -
      #
      # @param arg [Boolean] whether to automatically wipe any preexisting signatures
      #
      # @return [Boolean] the wipe_signature setting
      #
      def wipe_signatures(arg = nil)
        set_or_return(
          :wipe_signatures,
          arg,
          kind_of: [TrueClass, FalseClass],
          default: false
        )
      end

      # A shortcut for creating a thin pool (which is just a special type of logical volume) when creating the volume group
      #
      # @param name [String] the name of the thin pool
      # @param block [Proc] the block defining the lvm_thin_pool resource
      #
      # @return [Chef::Resource::LvmThinPool] the lvm_thin_pool resource
      #
      def thin_pool(name, &block)
        volume = lvm_thin_pool(name, &block)
        volume.action :nothing
        @logical_volumes << volume
        volume
      end

      # Attribute: ignore_skipped_cluster -
      #
      # @param arg [Boolean] whether to ignore skipped cluster VGs during LVM commands
      #
      # @return [Boolean] the ignore_skipped_cluster setting
      #
      def ignore_skipped_cluster(arg = nil)
        set_or_return(
          :ignore_skipped_cluster,
          arg,
          kind_of: [TrueClass, FalseClass],
          default: false
        )
      end
    end
  end
end
