#
# Cookbook:: lvm
# Library:: resource_lvm_thin_pool_meta_data
#
# Copyright:: 2016-2019, Ontario Systems, LLC.
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
      provides :lvm_thin_pool_meta_data

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

      # property: pool - The name of the thin pool logical volume in which this metadata volume exist
      property :pool, String, required: true

      # property: size - the size of thin pool metadata logical volume
      property :size, String, regex: /^(\d+[kKmMgGtT]|\d+)$/, required: true
    end
  end
end
