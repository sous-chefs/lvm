#
# Cookbook:: lvm
# Library:: resource_lvm_logical_volume
#
# Copyright:: 2009-2019, Chef Software, Inc.
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
      provides :lvm_logical_volume

      default_action :create
      allowed_actions :create, :resize, :remove

      # Initializes the lvm_logical_volume resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def initialize(name, run_context = nil)
        super
        @provider = Chef::Provider::LvmLogicalVolume
      end

      # property: physical_volumes - list of physical volumes to be used for creation
      property :physical_volumes, [String, Array]

      # property: stripes - number of stripes for the volume
      property :stripes, Integer,
        callbacks: {
          'must be greater than 0' => proc { |value| value > 0 },
        }

      # property: stripe_size - the stripe size
      property :stripe_size, Integer,
        callbacks: {
          'must be a power of 2' => proc { |value| (Math.log2(value) % 1) == 0 },
        }

      # property: mirrors - number of mirrors for the volume
      property :mirrors, Integer,
        callbacks: {
          'must be greater than 0' => proc { |value| value > 0 },
        }

      # property: contiguous - whether to use contiguous allocation policy
      property :contiguous, [true, false]

      # property: readahead - the read ahead sector count of the logical volume
      property :readahead, [Integer, String],
        equal_to: [2..120, 'auto', 'none'].flatten!

      # property: take_up_free_space - whether to have the LV take up the remainder of free space on the VG
      property :take_up_free_space, [true, false]

      # property: wipe_signature -
      property :wipe_signatures, [true, false], default: false

      # property: ignore_skipped_cluster -
      property :ignore_skipped_cluster, [true, false], default: false

      # property: remove_mount_point - whether to remove the mount location/directory
      property :remove_mount_point, [true, false]
    end
  end
end
