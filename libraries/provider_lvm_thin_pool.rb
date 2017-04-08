#
# Cookbook:: lvm
# Library:: provider_lvm_thin_pool
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
    # The provider for lvm_thin_pool resource
    #
    class LvmThinPool < Chef::Provider::LvmLogicalVolume
      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmThinPool] the lvm_logical_volume resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmThinPool.new(@new_resource.name)
        @current_resource
      end

      def action_create
        super
        process_thin_volumes(:create)
      end

      def action_resize
        super
        process_thin_volumes(:resize)
      end

      protected

      def create_command
        super.sub('--name', '--thinpool')
      end

      private

      def process_thin_volumes(action)
        updates = []
        new_resource.thin_volumes.each do |tv|
          tv.group new_resource.group
          tv.pool new_resource.name
          tv.run_action action
          updates << tv.updated?
        end
        new_resource.updated_by_last_action(updates.any?)
      end
    end
  end
end
