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

class Chef
  class Provider
    class LvmLogicalVolume < Chef::Provider
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmLogicalVolume.new(@new_resource.name)
        @current_resource
      end

      def action_create
        require 'lvm'
        require 'mixlib/shellout'
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
            when /(\d{2}|100)%(FREE|VG|PVS)/
              "--extents #{new_resource.size}"
            when /(\d+)/
              "--size #{$1}"
            end
          stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
          stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
          mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''
          contiguous = new_resource.contiguous ? "--contiguous y" : ''
          readahead = new_resource.readahead ? "--readahead #{new_resource.readahead}" : ''
          physical_volumes = [new_resource.physical_volumes].flatten.join ' ' if new_resource.physical_volumes

          command = "lvcreate #{size} #{stripes} #{stripe_size} #{mirrors} #{contiguous} #{readahead} --name #{name} #{group} #{physical_volumes}"
          Chef::Log.debug "Executing lvm command: '#{command}'"
          output = lvm.raw(command)
          Chef::Log.debug "Command output: '#{output}'"
          new_resource.updated_by_last_action true
        else
          Chef::Log.info "Logical volume '#{name}' already exists. Not creating..."
        end

        # If file system is specified, format the logical volume
        if fs_type.nil?
          Chef::Log.info "File system type is not set. Not formatting..."
        elsif device_formatted?(device_name)
          Chef::Log.info "Volume '#{device_name}' is already formatted. Not formatting..."
        else
          mkfs = ::Mixlib::ShellOut.new("yes | mkfs -t #{fs_type} #{device_name}")
          mkfs.run_command.error!

          Chef::Log.debug "mkfs.exitstatus: #{mkfs.exitstatus}"
          Chef::Log.debug "mkfs.stdout: #{mkfs.stdout.inspect}"
          Chef::Log.debug "mkfs.stderr: #{mkfs.stderr.inspect}"
        end

        # If the mount point is specified, mount the logical volume
        if new_resource.mount_point
          if new_resource.mount_point.is_a?(String)
            mount_spec = {:location => new_resource.mount_point}
          else
            mount_spec = new_resource.mount_point
          end

          # Create the mount point
          directory mount_spec[:location] do
            mode 0777
            owner 'root'
            group 'root'
            recursive true
          end

          # Mount the logical volume
          mount mount_spec[:location] do
            options mount_spec[:options]
            dump mount_spec[:dump]
            pass mount_spec[:pass]
            device device_name
            fstype fs_type
            action [:mount, :enable]
          end
        end
      end

    private

      def to_dm_name(name)
        # The device mapper will double any hyphens found in a volume group or
        # logical volume name so that it can properly locate the separator between
        # the volume group and the logical volume in the device name.
        name.gsub(/-/, '--')
      end

      def device_formatted?(device_name)
        require 'mixlib/shellout'
        Chef::Log.debug "Checking to see if #{device_name} is formatted..."
        blkid = ::Mixlib::ShellOut.new "blkid -o value -s TYPE #{device_name}"

        Chef::Log.debug "Result of check: #{blkid}"
        Chef::Log.debug "blkid.exitstatus: #{blkid.exitstatus}"
        Chef::Log.debug "blkid.stdout: #{blkid.stdout.inspect}"
        blkid.exitstatus == 0 && blkid.stdout.strip == fs_type.strip
      end
    end
  end
end
