#
# Cookbook Name:: lvm
# Library:: provider_lvm_logical_volume
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
    # The provider for lvm_logical_volume resource
    #
    class LvmLogicalVolume < Chef::Provider
      include Chef::Mixin::ShellOut

      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmLogicalVolume.new(@new_resource.name)
        @current_resource
      end

      # The create action
      #
      def action_create # rubocop:disable MethodLength
        require 'lvm'
        lvm = LVM::LVM.new
        name = new_resource.name
        group = new_resource.group
        fs_type = new_resource.filesystem
        device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"

        vg = lvm.volume_groups[new_resource.group]
        # Create the logical volume
        if vg.nil? || vg.logical_volumes.select { |lv| lv.name == name }.empty?
          device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
          size =
            case new_resource.size
            when /\d+[kKmMgGtT]/
              "--size #{new_resource.size}"
            when /(\d{1,2}|100)%(FREE|VG|PVS)/
              "--extents #{new_resource.size}"
            when /(\d+)/
              "--size #{$1}" # rubocop:disable PerlBackrefs
            end

          stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
          stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
          mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''
          contiguous = new_resource.contiguous ? '--contiguous y' : ''
          readahead = new_resource.readahead ? "--readahead #{new_resource.readahead}" : ''
          physical_volumes = [new_resource.physical_volumes].flatten.join ' ' if new_resource.physical_volumes

          command = "lvcreate #{size} #{stripes} #{stripe_size} #{mirrors} #{contiguous} #{readahead} --name #{name} #{group} #{physical_volumes}"
          Chef::Log.debug "Executing lvm command: '#{command}'"
          output = lvm.raw(command)
          Chef::Log.debug "Command output: '#{output}'"
          new_resource.updated_by_last_action(true)
        else
          Chef::Log.info "Logical volume '#{name}' already exists. Not creating..."
        end

        # If file system is specified, format the logical volume
        if fs_type.nil?
          Chef::Log.info 'File system type is not set. Not formatting...'
        elsif device_formatted?(device_name, fs_type)
          Chef::Log.info "Volume '#{device_name}' is already formatted. Not formatting..."
        else
          shell_out!("yes | mkfs -t #{fs_type} #{device_name}")
          new_resource.updated_by_last_action(true)
        end

        # If the mount point is specified, mount the logical volume
        if new_resource.mount_point
          if new_resource.mount_point.is_a?(String)
            mount_spec = { :location => new_resource.mount_point }
          else
            mount_spec = new_resource.mount_point
          end

          # Create the mount point
          dir_resource = directory mount_spec[:location] do
            mode 0777
            owner 'root'
            group 'root'
            recursive true
            action :nothing
          end
          dir_resource.run_action(:create)
          # Mark the resource as updated if the directory resource is updated
          new_resource.updated_by_last_action(dir_resource.updated?)

          # Mount the logical volume
          mount_resource = mount mount_spec[:location] do
            options mount_spec[:options]
            dump mount_spec[:dump]
            pass mount_spec[:pass]
            device device_name
            fstype fs_type
            action :nothing
          end
          mount_resource.run_action(:mount)
          mount_resource.run_action(:enable)
          # Mark the resource as updated if the mount resource is updated
          new_resource.updated_by_last_action(mount_resource.updated?)
        end
      end

      private

        # Converts the device name to the dm name format
        #
        # The device mapper will double any hyphens found in a volume group or
        # logical volume name so that it can properly locate the separator between
        # the volume group and the logical volume in the device name.
        #
        # @param name [String] the name to map
        #
        # @return [String] the mapped dm name
        #
        def to_dm_name(name)
          name.gsub(/-/, '--')
        end

        # Checks if the device is formatted with the given file system type
        #
        # @param device_name [String] the device name
        # @param fs_type [String] the file system type
        #
        # @return [Boolean] whether the device is formatted with the given file
        #   system type or not
        #
        def device_formatted?(device_name, fs_type)
          Chef::Log.debug "Checking to see if #{device_name} is formatted..."
          # Do not raise when there is an error in running the blkid command. If the exitstatus is not 0,
          # the device is perhaps not formatted.
          blkid = shell_out("blkid -o value -s TYPE #{device_name}")
          blkid.exitstatus == 0 && blkid.stdout.strip == fs_type.strip
        end
    end
  end
end
