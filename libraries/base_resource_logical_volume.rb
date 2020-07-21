#
# Cookbook:: lvm
# Library:: base_resource_logical_volume
#
# Copyright:: 2009-2020, Chef Software, Inc.
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
    # Base class that contains common properties for all logical volume resources
    # This class is only meant to be used as a base class for other resources.
    #
    class BaseLogicalVolume < Chef::Resource # cookstyle: disable ChefDeprecations/HWRPWithoutProvides
      # property: name - name of the logical volume
      property :name, String, name_property: true, required: true,
        regex: /[\w+.-]+/,
        callbacks: {
          "cannot be '.', '..', 'snapshot', or 'pvmove'" => proc do |value|
            !(value == '.' || value == '..' || value == 'snapshot' || value == 'pvmove')
          end,
          "cannot contain the strings '_mlog' or '_mimage'" => proc do |value|
            !value.match(/.*(_mlog|_mimage).*/)
          end,
        }

      # property: group - the volume group the logical volume belongs to
      property :group, String

      # property: lv_params - additional parameters for lvcreate
      property :lv_params, String

      # property: size - size of the logical volume
      property :size, String,
        regex: /^(\d+[kKmMgGtTpPeE]|(\d{1,2}|100)%(FREE|VG|PVS)|\d+)$/,
        required: true

      # property: filesystem - the file system type
      property :filesystem, String

      # property: filesystem_params - the file system parameters
      property :filesystem_params, String

      # property: mount_point - mount point for the logical volume
      property :mount_point, [String, Hash],
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
    end
  end
end
