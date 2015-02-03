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
      include Chef::DSL::Recipe
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
        updates = []

        vg = lvm.volume_groups[new_resource.group]
        # Create the logical volume
        if vg.nil? || vg.logical_volumes.select { |lv| lv.name == name }.empty?
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
          updates << true
        else
          lv = vg.logical_volumes.select { |lv| lv.name == name }.first
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
          shell_out!("yes | mkfs -t #{fs_type} #{device_name}")
          updates << true
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
            mode 0755
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
            dump mount_spec[:dump]
            pass mount_spec[:pass]
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
        require 'lvm'
        lvm = LVM::LVM.new

        vg = lvm.volume_groups[new_resource.group]
        # if doing a resize make sure that the volume exists before doing anything
        if vg.nil?
          Chef::Application.fatal!("Error volume group #{new_resource.group} does not exist", 2 )
        else
          lv = vg.logical_volumes.select do |lvs|
            lvs.name == new_resource.name
          end
          # make sure that the LV specified exists in the VG specified
          Chef::Application.fatal!("Error logical volume #{new_resource.name} does not exist", 2 ) if lv.empty?
        end

        lv = lv.first
        pe_size = lvm.volume_groups[new_resource.group].extent_size.to_i
        pe_free = lvm.volume_groups[new_resource.group].free_count.to_i
        pe_count = lvm.volume_groups[new_resource.group].extent_count.to_i
        pe_allocated = pe_count - pe_free
        lv_size_cur = lv.size.to_i / pe_size

        lv_size = new_resource.size
        lv_size = "100%FREE" if new_resource.take_up_free_space

        group = new_resource.group

        
        # figure out how we should calculate extents
        resize_type = case lv_size
            when /^\d+[kKmMgGtT]$/
                "byte"
            when /^(\d{1,2}|100)%(FREE|VG|PVS)$/
                "percent"
            when /^(\d+)$/
                "extent"
        end

        # calculate extents based off of an explicit size
        # if not suffix is supplied assume extents is what is being specified
        if resize_type == "byte" || resize_type == "extent"
          lv_size_req = case lv_size
                          when /^(\d+)(k|K)$/
                            ($1.to_i *1024) / pe_size
                          when /^(\d+)(m|M)$/
                            ($1.to_i * 1048576) / pe_size
                          when /^(\d+)(g|G)$/
                            ($1.to_i * 1073741824) / pe_size
                          when /^(\d+)(t|T)$/
                            ($1.to_i * 1099511627776) / pe_size
                          when /^(\d+)$/
                            $1.to_i
                          else
                            Chef::Application.fatal!("Invalid size #{$1} for lvm resize", 2)
                        end
        # calcuate the number of extents needed differently if specifying a percentage
        elsif resize_type == "percent"
          percent,type = lv_size.scan(/(\d{1,2}|100)%(FREE|VG|PVS)/).first
          
          lv_size_req = case type
                          when "VG"
                            ((percent.to_f / 100) * pe_count).to_i
                          when "FREE"
                            Chef::Application.fatal!("Cannot percentage based off free space",2) unless new_resource.take_up_free_space
                            (((percent.to_f / 100) * pe_free) + lv_size_cur).to_i
                          else
                            Chef::Application.fatal!("Invalid type #{type} for resize. You can only resize using an explicit size, percentage of VG or by setting take_up_free_space to true", 2)
                        end
        else
           Chef::Application.fatal!("Invalid size specification #{lv_size}", 2)
        end


        Chef::Application.fatal!("Error trying to extend logical volume #{lv.name} beyond the capacity of volume group #{group}", 2 ) if ( lv_size_req - lv_size_cur ) > pe_free

        # don't resize if the current size is greater than or equal to the target size
        if lv_size_cur >= lv_size_req
          Chef::Log.debug "Logical volume #{lv.name} in volume group #{group} already at requested size"
        else
          Chef::Log.debug "Resizing logical volume #{lv.name} from #{lv_size_cur} pe to #{lv_size_req} pe with #{pe_free} pe left in volume group #{group}"

          resize_fs = "--resizefs"
          stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
          stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
          mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''

          command = "lvextend -l #{lv_size_req} #{resize_fs} #{stripes} #{stripe_size} #{mirrors} #{lv.path} "
          Chef::Log.debug "Running command: #{command}"
          output = lvm.raw command
          Chef::Log.debug "Command output: #{output}"

          # broadcast that we did a resize
          new_resource.updated_by_last_action true
        end
      end

      # Action to resize LV to specified size
      def action_resize
        require 'lvm'
        lvm = LVM::LVM.new

        vg = lvm.volume_groups[new_resource.group]
        # if doing a resize make sure that the volume exists before doing anything
        if vg.nil?
          Chef::Application.fatal!("Error volume group #{new_resource.group} does not exist", 2 )
        else
          lv = vg.logical_volumes.select do |lvs|
            lvs.name == new_resource.name
          end
          # make sure that the LV specified exists in the VG specified
          Chef::Application.fatal!("Error logical volume #{new_resource.name} does not exist", 2 ) if lv.empty?
        end

        lv = lv.first
        pe_size = lvm.volume_groups[new_resource.group].extent_size.to_i
        pe_free = lvm.volume_groups[new_resource.group].free_count.to_i
        pe_count = lvm.volume_groups[new_resource.group].extent_count.to_i
        pe_allocated = pe_count - pe_free
        lv_size_cur = lv.size.to_i / pe_size

        lv_size = new_resource.size
        lv_size = "100%FREE" if new_resource.take_up_free_space

        group = new_resource.group

        
        # figure out how we should calculate extents
        resize_type = case lv_size
            when /^\d+[kKmMgGtT]$/
                "byte"
            when /^(\d{1,2}|100)%(FREE|VG|PVS)$/
                "percent"
            when /^(\d+)$/
                "extent"
        end

        # calculate extents based off of an explicit size
        # if not suffix is supplied assume extents is what is being specified
        if resize_type == "byte" || resize_type == "extent"
          lv_size_req = case lv_size
                          when /^(\d+)(k|K)$/
                            ($1.to_i *1024) / pe_size
                          when /^(\d+)(m|M)$/
                            ($1.to_i * 1048576) / pe_size
                          when /^(\d+)(g|G)$/
                            ($1.to_i * 1073741824) / pe_size
                          when /^(\d+)(t|T)$/
                            ($1.to_i * 1099511627776) / pe_size
                          when /^(\d+)$/
                            $1.to_i
                          else
                            Chef::Application.fatal!("Invalid size #{$1} for lvm resize", 2)
                        end
        # calcuate the number of extents needed differently if specifying a percentage
        elsif resize_type == "percent"
          percent,type = lv_size.scan(/(\d{1,2}|100)%(FREE|VG|PVS)/).first
          
          lv_size_req = case type
                          when "VG"
                            ((percent.to_f / 100) * pe_count).to_i
                          when "FREE"
                            Chef::Application.fatal!("Cannot percentage based off free space",2) unless new_resource.take_up_free_space
                            (((percent.to_f / 100) * pe_free) + lv_size_cur).to_i
                          else
                            Chef::Application.fatal!("Invalid type #{type} for resize. You can only resize using an explicit size, percentage of VG or by setting take_up_free_space to true", 2)
                        end
        else
           Chef::Application.fatal!("Invalid size specification #{lv_size}", 2)
        end


        Chef::Application.fatal!("Error trying to extend logical volume #{lv.name} beyond the capacity of volume group #{group}", 2 ) if ( lv_size_req - lv_size_cur ) > pe_free

        # don't resize if the current size is greater than or equal to the target size
        if lv_size_cur >= lv_size_req
          Chef::Log.debug "Logical volume #{lv.name} in volume group #{group} already at requested size"
        else
          Chef::Log.debug "Resizing logical volume #{lv.name} from #{lv_size_cur} pe to #{lv_size_req} pe with #{pe_free} pe left in volume group #{group}"

          resize_fs = "--resizefs"
          stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
          stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
          mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''

          command = "lvextend -l #{lv_size_req} #{resize_fs} #{stripes} #{stripe_size} #{mirrors} #{lv.path} "
          Chef::Log.debug "Running command: #{command}"
          output = lvm.raw command
          Chef::Log.debug "Command output: #{output}"

          # broadcast that we did a resize
          new_resource.updated_by_last_action true
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
