#
# Cookbook Name:: lvm
# Library:: provider_lvm_volume_group
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

require 'chef/mixin/shell_out'

class Chef
  class Provider
    # The provider for lvm_volume_group resource
    #
    class LvmVolumeGroup < Chef::Provider
      include Chef::Mixin::ShellOut

      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmVolumeGroup] the lvm_volume_group resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmVolumeGroup.new(@new_resource.name)
        @current_resource
      end

      # The create action
      #
      def action_create
        require 'lvm'
        name = new_resource.name
        physical_volume_list = [new_resource.physical_volumes].flatten

        # Make sure any pvs are not being used as filesystems (e.g. ephemeral0 on
        # AWS is always mounted at /mnt as an ext3 fs).
        #
        physical_volume_list.select { |pv| ::File.exist?(pv) }.each do |pv|
          # If the device is mounted, the mount point will be returned else nil will be returned.
          # mount_point is required by the mount resource for umount and disable actions.
          #
          mount_point = get_mount_point(pv)
          unless mount_point.nil?
            mount_resource = mount mount_point do
              device pv
              action :nothing
            end
            mount_resource.run_action(:umount)
            mount_resource.run_action(:disable)
          end
        end

        lvm = LVM::LVM.new
        # Create the volume group
        if lvm.volume_groups[name]
          Chef::Log.info "Volume group '#{name}' already exists. Not creating..."
        else
          physical_volumes = physical_volume_list.join(' ')
          physical_extent_size = new_resource.physical_extent_size ? "-s #{new_resource.physical_extent_size}" : ''
          command = "vgcreate #{name} #{physical_extent_size} #{physical_volumes}"

          Chef::Log.debug "Executing lvm command: '#{command}'"
          output = lvm.raw command
          Chef::Log.debug "Command output: '#{output}'"
          # Create the logical volumes specified as sub-resources
          new_resource.logical_volumes.each do |lv|
            lv.group new_resource.name
            lv.run_action :create
          end
          new_resource.updated_by_last_action(true)
        end
      end

      private

      # Obtains the mount point of a device and returns nil if the device is not mounted
      #
      # @param device [String] the physical device
      #
      # @return [String] the mount point of the device if mounted and nil otherwise
      #
      def get_mount_point(device)
        mount_point = nil
        shell_out!('mount').stdout.each_line do |line|
          matched = line.match(/#{Regexp.escape(device)}\s+on\s+(.*)\s+type.*/)
          # If a match is found in the mount, obtain the mount point and return it
          unless matched.nil?
            mount_point = matched[1]
            break
          end
        end
        mount_point
      end
    end
  end
end
