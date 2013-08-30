#
# Cookbook Name:: lvm
# Library:: resource_lvm_physical_volume
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
    # The lvm_physical_volume resource
    #
    class LvmPhysicalVolume < Chef::Resource
      # Initializes lvm_physical_volume resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmPhysicalVolume] the lvm_physical_volume resource
      #
      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_physical_volume
        @action = :create
        @allowed_actions.push :create
        @provider = Chef::Provider::LvmPhysicalVolume
      end

      # Attribute: name - the physical device
      #
      # @param arg [String] the physical device
      #
      # @return [String] the physical device
      #
      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => String,
          :name_attribute => true,
          :required => true
        )
      end
    end
  end
end
