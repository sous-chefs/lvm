#
# Cookbook:: lvm
# Library:: resource_lvm_thin_pool
#
# Copyright:: 2016-2017, Ontario Systems, LLC.
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
require_relative 'resource_lvm_logical_volume'

class Chef
  class Resource
    # The lvm_thin_pool resource
    #
    # A thin pool is a logical volume that can contain thin volumes (which are also logical volumes but are "thin")
    class LvmThinPool < Chef::Resource::LvmLogicalVolume
      # Thin Logical volumes to be created in the thin pool
      attr_reader :thin_volumes

      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_thin_pool
        @provider = Chef::Provider::LvmThinPool
        @thin_volumes = []
      end

      # A shortcut for creating a thin volume (which is just a special type of logical volume) when creating the thin pool
      #
      # @param name [String] the name of the thin volume
      # @param block [Proc] the block defining the lvm_thin_volume resource
      #
      # @return [Chef::Resource::LvmThinVolume] the lvm_thin_volume resource
      #
      def thin_volume(name, &block)
        volume = lvm_thin_volume(name, &block)
        volume.action :nothing
        @thin_volumes << volume
        volume
      end
    end
  end
end
