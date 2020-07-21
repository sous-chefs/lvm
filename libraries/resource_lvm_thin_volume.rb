#
# Cookbook:: lvm
# Library:: resource_lvm_thin_volume
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
    # The lvm_thin_volume resource
    #
    # A thin pool is a logical volume that can contain thin volumes (which are also logical volumes but are "thin")
    class LvmThinVolume < Chef::Resource::BaseLogicalVolume
      resource_name :lvm_thin_volume
      provides :lvm_thin_volume

      default_action :create
      allowed_actions :create, :resize

      # Initializes the lvm_logical_volume resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def initialize(name, run_context = nil)
        super
        @provider = Chef::Provider::LvmThinVolume
      end

      # property: size - size of the logical volume
      property :size, String, regex: /^(\d+[kKmMgGtT]|\d+)$/, required: true

      # property: pool - The name of the thin pool logical volume in which this thin volume will be created
      property :pool, String, required: true

      # property: ignore_skipped_cluster -
      property :ignore_skipped_cluster, [true, false], default: false
    end
  end
end
