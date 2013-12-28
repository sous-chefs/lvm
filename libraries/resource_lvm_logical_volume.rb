#
# Cookbook Name:: lvm
# Library:: resource_lvm_logical_volume
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
    # The lvm_logical_volume resource
    #
    class LvmLogicalVolume < Chef::Resource
      # Initializes the lvm_logical_volume resource
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_logical_volume
        @action = :create
        @allowed_actions.push :create
        @provider = Chef::Provider::LvmLogicalVolume
      end

      # Attribute: name - name of the logical volume
      #
      # @param arg [String] the name of the logical volume
      #
      # @return [String] the name of the logical volume
      #
      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => String,
          :regex => /[\w+.-]+/,
          :name_attribute => true,
          :required => true,
          :callbacks => {
            "cannot be '.', '..', 'snapshot', or 'pvmove'" => proc do |value|
              !(value == '.' || value == '..' || value == 'snapshot' || value == 'pvmove')
            end,
            "cannot contain the strings '_mlog' or '_mimage'" => proc do |value|
              !value.match(/.*(_mlog|_mimage).*/)
            end
          }
        )
      end

      # Attribute: group - the volume group the logical volume belongs to
      #
      # @param arg [String] the volume group name
      #
      # @return [String] the volume group name
      #
      def group(arg = nil)
        set_or_return(
          :group,
          arg,
          :kind_of => String
        )
      end

      # Attribute: size - size of the logical volume
      #
      # @param arg [String] the size of the logical volume
      #
      # @return [String] the size of the logical volume
      #
      def size(arg = nil)
        set_or_return(
          :size,
          arg,
          :kind_of => String,
          :regex => /^(\d+[kKmMgGtTpPeE]|(\d{1,2}|100)%(FREE|VG|PVS)|\d+)$/,
          :required => true
        )
      end

      # Attribute: filesystem - the file system type
      #
      # @param arg [String] the file system type
      #
      # @return [String] the file system type
      #
      def filesystem(arg = nil)
        set_or_return(
          :filesystem,
          arg,
          :kind_of => String
        )
      end

      # Attribute: mount_point - mount point for the logical volume
      #
      # @param arg [String] the mount point
      #
      # @return [String] the mount point
      #
      def mount_point(arg = nil)
        set_or_return(
          :mount_point,
          arg,
          :kind_of => [String, Hash],
          :callbacks => {
            ': location is required!' => proc do |value|
              value.class == String || (value[:location] && !value[:location].empty?)
            end,
            ': location must be an absolute path!' => proc do |value|
              # this can be a string or a hash, so attempt to match either for
              # the regex
              matches = value =~ /^\/[^\0]*/ || value[:location] =~ /^\/[^\0]*/
              !matches.nil?
            end
          }
        )
      end

      # Attribute: physical_volumes - list of physical volumes to be used for creation
      #
      # @param arg [String, Array] - list of physical devices
      #
      # @return [String, Array] - list of physical devices
      #
      def physical_volumes(arg = nil)
        set_or_return(
          :physical_volumes,
          arg,
          :kind_of => [String, Array]
        )
      end

      # Attribute: stripes - number of stripes for the volume
      #
      # @param arg [String] number of stripes
      #
      # @return [String] number of stripes
      #
      def stripes(arg = nil)
        set_or_return(
          :stripes,
          arg,
          :kind_of => Integer,
          :callbacks => {
            'must be greater than 0' => proc { |value| value > 0 }
          }
        )
      end

      # Attribute: stripe_size - the stripe size
      #
      # @param arg [String] the stripe size
      #
      # @return [String] the stripe size
      #
      def stripe_size(arg = nil)
        set_or_return(
          :stripe_size,
          arg,
          :kind_of => Integer,
          :callbacks => {
            'must be a power of 2' => proc { |value| Math.log2(value) % 1 == 0 }
          }
        )
      end

      # Attribute: mirrors - number of mirrors for the volume
      #
      # @param arg [Integer] number of mirrors
      #
      # @return [Integer] number of mirrors
      #
      def mirrors(arg = nil)
        set_or_return(
          :mirrors,
          arg,
          :kind_of => Integer,
          :callbacks => {
            'must be greater than 0' => proc { |value| value > 0 }
          }
        )
      end

      # Attribute: contiguous - whether to use contiguous allocation policy
      #
      # @param arg [Boolean] whether to use contiguous allocation policy
      #
      # @return [Boolean] the contiguous allocation policy setting
      #
      def contiguous(arg = nil)
        set_or_return(
          :contiguous,
          arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      # Attribute: readahead - the read ahead sector count of the logical volume
      #
      # @param arg [Integer, String] the read ahead sector count
      #
      # @return [Integer, String] the read ahead sector count
      #
      def readahead(arg = nil)
        set_or_return(
          :readahead,
          arg,
          :kind_of => [Integer, String],
          :equal_to => [2..120, 'auto', 'none'].flatten!
        )
      end
    end
  end
end
