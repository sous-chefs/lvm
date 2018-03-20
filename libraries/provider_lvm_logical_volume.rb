#
# Cookbook:: lvm
# Library:: provider_lvm_logical_volume
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
require 'chef/dsl/platform_introspection'
require File.join(File.dirname(__FILE__), 'lvm')

class Chef
  class Provider
    # The provider for lvm_logical_volume resource
    #
    class LvmLogicalVolume < Chef::Provider
      include Chef::DSL::Recipe
      include Chef::Mixin::ShellOut
      include Chef::DSL::PlatformIntrospection
      include LVMCookbook

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
      def action_create
        require_lvm_gems
        install_filesystem_deps

        lvm = LVM::LVM.new
        name = new_resource.name
        group = new_resource.group
        fs_type = new_resource.filesystem
        fs_params = new_resource.filesystem_params
        device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
        updates = []

        vg = lvm.volume_groups[group]
        # Create the logical volume
        if vg.nil? || vg.logical_volumes.select { |lv| lv.name == name }.empty?
          command = create_command
          Chef::Log.debug "Executing lvm command: '#{command}'"
          output = lvm.raw(command)
          Chef::Log.debug "Command output: '#{output}'"
          updates << true
        else
          lv = vg.logical_volumes.find { |v| v.name == name }
          if !lv.state.nil? && lv.state.to_sym == :active
            Chef::Log.info "Logical volume '#{name}' already exists and active. Not creating..."
          else
            Chef::Log.info "Logical volume '#{name}' already created and inactive. Activating now..."
            command = "lvchange -a y #{device_name}"
            Chef::Log.debug "Executing lvm command: '#{command}'"
            output = lvm.raw(command)
            Chef::Log.debug "Command output: '#{output}'"
            updates << true
          end
        end

        # If file system is specified, format the logical volume
        if fs_type.nil?
          Chef::Log.info 'File system type is not set. Not formatting...'
        elsif device_formatted?(device_name, fs_type)
          Chef::Log.info "Volume '#{device_name}' is already formatted. Not formatting..."
        else
          shell_out!("yes | mkfs -t #{fs_type} #{fs_params} #{device_name}")
          updates << true
        end

        # If the mount point is specified, mount the logical volume
        if new_resource.mount_point

          mount_spec = if new_resource.mount_point.is_a?(String)
                         { location: new_resource.mount_point }
                       else
                         new_resource.mount_point
                       end

          # Create the mount point
          dir_resource = directory mount_spec[:location] do
            mode '755'
            owner 'root'
            group 'root'
            recursive true
            action :nothing
            not_if { Pathname.new(mount_spec[:location]).mountpoint? }
          end
          dir_resource.run_action(:create)
          # Mark the resource as updated if the directory resource is updated
          updates << dir_resource.updated?

          # Mount the logical volume
          mount_resource = mount mount_spec[:location] do
            options mount_spec[:options]
            dump mount_spec[:dump] if mount_spec[:dump]
            pass mount_spec[:pass] if mount_spec[:pass]
            device device_name
            fstype fs_type
            action :nothing
          end
          mount_resource.run_action(:mount)
          mount_resource.run_action(:enable)
          # Mark the resource as updated if the mount resource is updated
          updates << mount_resource.updated?
        end
        new_resource.updated_by_last_action(updates.any?)
      end

      # Action to resize LV to specified size
      def action_resize
        require_lvm_gems
        lvm = LVM::LVM.new
        name = new_resource.name
        group = new_resource.group

        vg = lvm.volume_groups[group]
        # if doing a resize make sure that the volume exists before doing anything

        raise("Error volume group #{group} does not exist") if vg.nil?

        lv = vg.logical_volumes.select do |lvs|
          lvs.name == name
        end
        # make sure that the LV specified exists in the VG specified
        raise("Error logical volume #{name} does not exist") if lv.empty?

        lv = lv.first
        pe_size = lvm.volume_groups[group].extent_size.to_i
        pe_free = lvm.volume_groups[group].free_count.to_i
        pe_count = lvm.volume_groups[group].extent_count.to_i
        lv_size_cur = lv.size.to_i / pe_size

        lv_size = new_resource.size
        lv_size = '100%FREE' if new_resource.respond_to?(:take_up_free_space) && new_resource.take_up_free_space

        # figure out how we should calculate extents
        resize_type = case lv_size
                      when /^\d+[kKmMgGtT]$/
                        'byte'
                      when /^(\d{1,2}|100)%(FREE|VG|PVS)$/
                        'percent'
                      when /^(\d+)$/
                        'extent'
                      end

        # calculate extents based off of an explicit size
        # if not suffix is supplied assume extents is what is being specified
        if resize_type == 'byte' || resize_type == 'extent'
          lv_size_req = case lv_size
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
        # calculate the number of extents needed differently if specifying a percentage
        elsif resize_type == 'percent'
          percent, type = lv_size.scan(/(\d{1,2}|100)%(FREE|VG|PVS)/).first

          lv_size_req = case type
                        when 'VG'
                          ((percent.to_f / 100) * pe_count).to_i
                        when 'FREE'
                          raise('Cannot percentage based off free space') unless new_resource.take_up_free_space
                          (((percent.to_f / 100) * pe_free) + lv_size_cur).to_i
                        else
                          raise("Invalid type #{type} for resize. You can only resize using an explicit size, percentage of VG or by setting take_up_free_space to true")
                        end
        else
          raise("Invalid size specification #{lv_size}")
        end

        raise("Error trying to extend logical volume #{lv.name} beyond the capacity of volume group #{group}") if !thin_volume? && (lv_size_req - lv_size_cur) > pe_free

        # don't resize if the current size is greater than or equal to the target size
        if lv_size_cur >= lv_size_req
          Chef::Log.debug "Logical volume #{lv.name} in volume group #{group} already at requested size"
        else
          Chef::Log.debug "Resizing logical volume #{lv.name} from #{lv_size_cur} pe to #{lv_size_req} pe with #{pe_free} pe left in volume group #{group}"

          command = resize_command(lv_size_req)
          Chef::Log.debug "Running command: #{command}"
          output = lvm.raw command
          Chef::Log.debug "Command output: #{output}"

          # broadcast that we did a resize
          new_resource.updated_by_last_action true
        end
      end

      protected

      def install_filesystem_deps
        if platform_family?('suse') && /^ext/.match(new_resource.filesystem)
          Chef::Log.debug('Installing e2fsprogs to create the filesystem')
          package 'e2fsprogs'
        else
          Chef::Log.debug('Not installing any packages to configure the filesystem')
        end
      end

      def thin_volume?
        false
      end

      def create_command
        size =
          case new_resource.size
          when /\d+[kKmMgGtT]/
            "--size #{new_resource.size}"
          when /(\d{1,2}|100)%(FREE|VG|PVS)/
            "--extents #{new_resource.size}"
          when /(\d+)/
            "--extents #{$1}" # rubocop:disable PerlBackrefs
          end

        stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
        stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
        mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''
        contiguous = new_resource.contiguous ? '--contiguous y' : ''
        readahead = new_resource.readahead ? "--readahead #{new_resource.readahead}" : ''
        yes_flag = new_resource.wipe_signatures == true ? '--yes' : ''
        lv_params = new_resource.lv_params
        name = new_resource.name
        group = new_resource.group
        physical_volumes = [new_resource.physical_volumes].flatten.join ' ' if new_resource.physical_volumes

        "lvcreate #{size} #{stripes} #{stripe_size} #{mirrors} #{contiguous} #{readahead} #{lv_params} --name #{name} #{group} #{physical_volumes} #{yes_flag}"
      end

      def resize_command(lv_size_req)
        name = new_resource.name
        group = new_resource.group
        device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
        resize_fs = '--resizefs'
        stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
        stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
        mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''

        "lvextend -l #{lv_size_req} #{resize_fs} #{stripes} #{stripe_size} #{mirrors} #{device_name}"
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
