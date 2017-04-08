#
# Cookbook:: lvm
# Library:: provider_lvm_thin_volume
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

require_relative 'provider_lvm_logical_volume'

class Chef
  class Provider
    # The provider for lvm_thin_volume resource
    #
    class LvmThinVolume < Chef::Provider::LvmLogicalVolume
      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmThinVolume] the lvm_logical_volume resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmThinVolume.new(@new_resource.name)
        @current_resource
      end

      protected

      def thin_volume?
        true
      end

      def create_command
        size = "--virtualsize #{new_resource.size}"
        lv_params = new_resource.lv_params
        name = new_resource.name
        group = new_resource.group
        pool = new_resource.pool

        "lvcreate #{size} #{lv_params} --thin --name #{name} #{group}/#{pool}"
      end

      def resize_command(lv_size_req)
        name = new_resource.name
        group = new_resource.group
        device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
        resize_fs = '--resizefs'

        "lvextend -l #{lv_size_req} #{resize_fs} #{device_name}"
      end
    end
  end
end
