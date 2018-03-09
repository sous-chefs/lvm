#
# Cookbook:: lvm
# Library:: provider_lvm_volume_group
#
# Copyright:: 2009-2017, Chef Software, Inc.
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
    # The provider for lvm_volume_group resource
    #
    class LvmVolumeGroup < Chef::Provider
      include Chef::DSL::Recipe
      include Chef::Mixin::ShellOut
      include LVMCookbook

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
        require_lvm_gems
        name = new_resource.name
        physical_volume_list = [new_resource.physical_volumes].flatten

        # Make sure any pvs are not being used as filesystems (e.g. ephemeral0 on
        # AWS is always mounted at /mnt as an ext3 fs).
        #
        create_mount_resource(physical_volume_list)

        # The notifications should be set if the lvm_volume_group or any of its sub lvm_logical_volume resources are
        # updated.

        lvm = LVM::LVM.new
        # Create the volume group
        create_volume_group(lvm, physical_volume_list, name)

        # Create the logical volumes specified as sub-resources
        create_logical_volumes
      end

      # The extend action
      #
      def action_extend
        require_lvm_gems
        name = new_resource.name
        physical_volume_list = [new_resource.physical_volumes].flatten
        lvm = LVM::LVM.new

        # verify that the volume group is valid
        raise("VG #{name} is not a valid volume group") if lvm.volume_groups[name].nil?

        # get uuid of the volume group so we can compare it to the VG the PV belongs to
        vg_uuid = lvm.volume_groups[name].uuid

        pvs_to_add = []
        physical_volume_list.each do |pv_name|
          pv = lvm.physical_volumes[pv_name]

          # get the uuid of the VG the PV belongs to if it exists
          # if we get "nil" then the PV does not belong to a VG
          # per the vgextend man page the pv will be initalized if it isn't already pv
          pv_vg_uuid = pv.nil? ? nil : pv.vg_uuid
          if pv_vg_uuid.nil?
            pvs_to_add.push pv_name
          else
            # raise an error if we attempt to add a PV that is already a member of a VG
            raise("PV #{pv} is already a member of another volume group. Cannot add to #{name}") unless pv_vg_uuid == vg_uuid
          end
        end

        return if pvs_to_add.empty?
        command = "vgextend #{name} #{pvs_to_add.join(' ')}"
        Chef::Log.debug "Executing lvm command: '#{command}'"
        output = lvm.raw command
        Chef::Log.debug "Command output: '#{output}'"
        new_resource.updated_by_last_action(true)
        resize_logical_volumes
      end

      private

      def create_mount_resource(physical_volume_list)
        physical_volume_list.select { |pv| ::File.exist?(pv) }.each do |pv|
          # If the device is mounted, the mount point will be returned else nil will be returned.
          # mount_point is required by the mount resource for umount and disable actions.
          #
          mount_point = get_mount_point(pv)
          next if mount_point.nil?

          mount_resource = mount mount_point do
            device pv
            action :nothing
          end
          mount_resource.run_action(:umount)
          mount_resource.run_action(:disable)
        end
      end

      def create_volume_group(lvm, physical_volume_list, name)
        if lvm.volume_groups[name]
          Chef::Log.info "Volume group '#{name}' already exists. Not creating..."
        else
          physical_volumes = physical_volume_list.join(' ')
          physical_extent_size = new_resource.physical_extent_size ? "-s #{new_resource.physical_extent_size}" : ''
          yes_flag = new_resource.wipe_signatures == true ? '--yes' : ''
          command = "vgcreate #{name} #{physical_extent_size} #{physical_volumes} #{yes_flag}"
          Chef::Log.debug "Executing lvm command: '#{command}'"
          output = lvm.raw command
          Chef::Log.debug "Command output: '#{output}'"
          new_resource.updated_by_last_action(true)
        end
      end

      def create_logical_volumes
        updates = []
        new_resource.logical_volumes.each do |lv|
          lv.group new_resource.name
          lv.run_action :create
          updates << lv.updated?
        end
        new_resource.updated_by_last_action(updates.any?)
      end

      def resize_logical_volumes
        updates = []
        new_resource.logical_volumes.each do |lv|
          lv.group new_resource.name
          lv.run_action :resize
          updates << lv.updated?
        end
        new_resource.updated_by_last_action(updates.any?)
      end

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
