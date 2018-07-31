#
# Cookbook:: lvm
# Library:: provider_lvm_thin_pool_meta_data
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

require 'chef/provider'
require 'chef/mixin/shell_out'
require 'chef/dsl/recipe'
require File.join(File.dirname(__FILE__), 'lvm')

class Chef
  class Provider
    # The provider for lvm_thin_volume resource
    #
    class LvmThinPoolMetaData < Chef::Provider
      include Chef::DSL::Recipe
      include Chef::Mixin::ShellOut
      include LVMCookbook

      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmThinPoolMetaData] the lvm_thin_pool_meta_data resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmThinPoolMetaData.new(@new_resource.name)
        @current_resource
      end

      def action_resize
        require_lvm_gems
        lvm = LVM::LVM.new
        name = new_resource.name
        group = new_resource.group
        pool = new_resource.pool
        vg = lvm.volume_groups[group]

        # if doing a resize make sure that the volume exists before doing anything
        raise("Error volume group #{group} does not exist") if vg.nil?

        lv = vg.logical_volumes.select do |lvs|
          lvs.name == pool
        end

        # make sure that the thin pool / volume specified exists in the VG specified.
        raise("Error logical volume (thin pool) #{pool} does not exist") if lv.empty?

        lv_metadata = vg.logical_volumes.select do |lvs|
          lvs.metadata_lv == "[#{name}]"
        end

        # make sure that the thin pool metadata specified exists in the VG specified
        raise("Error logical volume thin pool metadata volume #{name} does not exist") if lv_metadata.empty?

        lv_metadata = lv_metadata.first
        pe_size = vg.extent_size.to_i
        lv_metadata_size_cur = lv_metadata.metadata_size.to_i / pe_size

        lv_metadata_size = new_resource.size
        lv_metadata_size_req = case lv_metadata_size
                               when /^(\d+)(k|K)$/
                                 (Regexp.last_match[1].to_i * 1024) / pe_size
                               when /^(\d+)(m|M)$/
                                 (Regexp.last_match[1].to_i * 1_048_576) / pe_size
                               when /^(\d+)(g|G)$/
                                 (Regexp.last_match[1].to_i * 1_073_741_824) / pe_size
                               when /^(\d+)(t|T)$/
                                 (Regexp.last_match[1].to_i * 1_099_511_627_776) / pe_size
                               when /^(\d+)$/
                                 Regexp.last_match[1].to_i
                               else
                                 raise("Invalid size #{Regexp.last_match[1]} for lvm resize")
                               end

        if lv_metadata_size_cur >= lv_metadata_size_req
          Chef::Log.debug "Logical volume thin pool metadata #{lv_metadata.name} in volume group #{group} already at requested size"
        else
          command = resize_command(new_resource.size)
          Chef::Log.debug "Running command: #{command}"
          output = lvm.raw command
          Chef::Log.debug "Command output: #{output}"
          # broadcast that we did a resize
          new_resource.updated_by_last_action true
        end
      end

      protected

      def resize_command(lv_size_req)
        group = new_resource.group
        pool = new_resource.pool
        "lvextend --poolmetadatasize #{lv_size_req} #{group}/#{pool}"
      end
    end
  end
end
