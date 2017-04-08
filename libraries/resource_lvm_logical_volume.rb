#
# Cookbook:: lvm
# Library:: resource_lvm_logical_volume
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
require_relative 'base_resource_logical_volume'

class Chef
  class Resource
    # The lvm_logical_volume resource
    #
    class LvmLogicalVolume < Chef::Resource::BaseLogicalVolume
      # Initializes the lvm_logical_volume resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_logical_volume
        @action = :create
        @allowed_actions.push :create
        @allowed_actions.push :resize
        @provider = Chef::Provider::LvmLogicalVolume
      end

      # Attribute: physical_volumes - list of physical volumes to be used for creation
      #
      # @param arg [String, Array] - list of physical devices
      #
      # @return [String, Array] - list of physical devices
      #
      def physical_volumes(arg = nil)
        set_or_return(
          :physical_volumes,
          arg,
          kind_of: [String, Array]
        )
      end

      # Attribute: stripes - number of stripes for the volume
      #
      # @param arg [String] number of stripes
      #
      # @return [String] number of stripes
      #
      def stripes(arg = nil)
        set_or_return(
          :stripes,
          arg,
          kind_of: Integer,
          callbacks: {
            'must be greater than 0' => proc { |value| value > 0 },
          }
        )
      end

      # Attribute: stripe_size - the stripe size
      #
      # @param arg [String] the stripe size
      #
      # @return [String] the stripe size
      #
      def stripe_size(arg = nil)
        set_or_return(
          :stripe_size,
          arg,
          kind_of: Integer,
          callbacks: {
            'must be a power of 2' => proc { |value| (Math.log2(value) % 1) == 0 },
          }
        )
      end

      # Attribute: mirrors - number of mirrors for the volume
      #
      # @param arg [Integer] number of mirrors
      #
      # @return [Integer] number of mirrors
      #
      def mirrors(arg = nil)
        set_or_return(
          :mirrors,
          arg,
          kind_of: Integer,
          callbacks: {
            'must be greater than 0' => proc { |value| value > 0 },
          }
        )
      end

      # Attribute: contiguous - whether to use contiguous allocation policy
      #
      # @param arg [Boolean] whether to use contiguous allocation policy
      #
      # @return [Boolean] the contiguous allocation policy setting
      #
      def contiguous(arg = nil)
        set_or_return(
          :contiguous,
          arg,
          kind_of: [TrueClass, FalseClass]
        )
      end

      # Attribute: readahead - the read ahead sector count of the logical volume
      #
      # @param arg [Integer, String] the read ahead sector count
      #
      # @return [Integer, String] the read ahead sector count
      #
      def readahead(arg = nil)
        set_or_return(
          :readahead,
          arg,
          kind_of: [Integer, String],
          equal_to: [2..120, 'auto', 'none'].flatten!
        )
      end

      # Attribute: take_up_free_space - whether to have the LV take up the remainder of free space on the VG
      #
      # @param arg [Boolean] whether to have the LV take up the remainder of free space
      #
      # @return [Boolean] if the LV should take the remainder of free space
      #
      def take_up_free_space(arg = nil)
        set_or_return(
          :take_up_free_space,
          arg,
          kind_of: [TrueClass, FalseClass]
        )
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
    end
  end
end
