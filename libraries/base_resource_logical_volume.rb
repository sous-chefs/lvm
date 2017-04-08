#
# Cookbook:: lvm
# Library:: base_resource_logical_volume
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

require 'chef/resource'

class Chef
  class Resource
    # Base class that contains common attributes for all logical volume resources
    #
    class BaseLogicalVolume < Chef::Resource
      include Chef::DSL::Recipe

      # Initializes a BaseLogicalVolume object.  This class is only meant to
      # be used as a base class for other resources.
      #
      # @param name [String] name of the resource
      # @param run_context [Chef::RunContext] the run context of chef run
      #
      # @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
      #
      def initialize(name, run_context = nil)
        super
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
          kind_of: String,
          regex: /[\w+.-]+/,
          name_attribute: true,
          required: true,
          callbacks: {
            "cannot be '.', '..', 'snapshot', or 'pvmove'" => proc do |value|
              !(value == '.' || value == '..' || value == 'snapshot' || value == 'pvmove')
            end,
            "cannot contain the strings '_mlog' or '_mimage'" => proc do |value|
              !value.match(/.*(_mlog|_mimage).*/)
            end,
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
          kind_of: String
        )
      end

      # Attribute: lv_params - additional parameters for lvcreate
      #
      # @param arg [String] the parameters
      #
      # @return [String] the parameters
      #
      def lv_params(arg = nil)
        set_or_return(
          :lv_params,
          arg,
          kind_of: String
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
          kind_of: String,
          regex: /^(\d+[kKmMgGtTpPeE]|(\d{1,2}|100)%(FREE|VG|PVS)|\d+)$/,
          required: true
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
          kind_of: String
        )
      end

      # Attribute: filesystem_params - the file system parameters
      #
      # @param arg [String] the file system parameters
      #
      # @return [String] the file system parameters
      #
      def filesystem_params(arg = nil)
        set_or_return(
          :filesystem_params,
          arg,
          kind_of: String
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
          kind_of: [String, Hash],
          callbacks: {
            ': location is required!' => proc do |value|
              value.class == String || (value[:location] && !value[:location].empty?)
            end,
            ': location must be an absolute path!' => proc do |value|
              # this can be a string or a hash, so attempt to match either for
              # the regex
              matches = case value
                        when String
                          value =~ %r{^/[^\0]*}
                        when Hash
                          value[:location] =~ %r{^/[^\0]*}
                        end
              !matches.nil?
            end,
          }
        )
      end
    end
  end
end
