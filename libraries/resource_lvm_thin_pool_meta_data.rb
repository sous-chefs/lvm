#
# Cookbook:: lvm
# Library:: resource_lvm_thin_pool_meta_data
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
require_relative 'base_resource_logical_volume'

class Chef
  class Resource
    # The lvm_thin_pool_meta_data resource
    #
    # A thin pool metadata is a thin pool's metadata logical volume
    class LvmThinPoolMetaData < Chef::Resource::BaseLogicalVolume
      resource_name :lvm_thin_pool_meta_data

      default_action :resize
      allowed_actions :resize

      # Initializes the lvm_thin_pool_meta_data resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmThinPoolMetaData] the lvm_thin_pool_meta_data resource
      #
      def initialize(name, run_context = nil)
        super
        @provider = Chef::Provider::LvmThinPoolMetaData
      end

      # Attribute: pool - The name of the thin pool logical volume in which this metadata volume exist
      #
      # @param arg [String] The name of the thin pool logical volume in which this metadata volume exist
      #
      # @return [String] The name of the thin pool logical volume in which this metadata volume exist
      #
      def pool(arg = nil)
        set_or_return(
          :pool,
          arg,
          kind_of: String,
          required: true
        )
      end

      # Attribute: size - the size of thin pool metadata logical volume
      #
      # @param arg [String] the size of thin pool metadata logical volume
      #
      # @return [String] the size of thin pool metadata logical volume
      #
      def size(arg = nil)
        set_or_return(
          :size,
          arg,
          kind_of: String,
          regex: /^(\d+[kKmMgGtT]|\d+)$/,
          required: true
        )
      end
    end
  end
end
