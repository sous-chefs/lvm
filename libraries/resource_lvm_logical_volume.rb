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
    class LvmLogicalVolume < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :lvm_logical_volume
        @action = :create
        @allowed_actions.push :create
        @provider = Chef::Provider::LvmLogicalVolume
      end

      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => String,
          :regex => /[\w+.-]+/,
          :name_attribute => true,
          :required => true,
          :callbacks => {
            "cannot be '.', '..', 'snapshot', or 'pvmove'" => Proc.new do |value|
              !(value == '.' || value == '..' || value == 'snapshot' || value == 'pvmove')
            end,
            "cannot contain the strings '_mlog' or '_mimage'" => Proc.new do |value|
              !value.match(/.*(_mlog|_mimage).*/)
            end
          }
        )
      end

      def group(arg = nil)
        set_or_return(
          :group,
          arg,
          :kind_of => String
        )
      end

      def size(arg = nil)
        set_or_return(
          :size,
          arg,
          :kind_of => String,
          :regex => /\d+[kKmMgGtT]|(\d{2}|100)%(FREE|VG|PVS)|\d+/,
          :required => true
        )
      end

      def filesystem(arg = nil)
        set_or_return(
          :filesystem,
          arg,
          :kind_of => String
        )
      end

      def mount_point(arg = nil)
        set_or_return(
          :mount_point,
          arg,
          :kind_of => [String, Hash],
          :callbacks => {
            ': location is required!' => Proc.new do |value|
              value.class == String || (value[:location] && !value[:location].empty?)
            end,
            ': location must be an absolute path!' => Proc.new do |value|
              # this can be a string or a hash, so attempt to match either for
              # the regex
              matches = value =~ %r{^/[^\0]*} || value[:location] =~ %r{^/[^\0]*}
              !matches.nil?
            end
          }
        )
      end

      def physical_volumes(arg = nil)
        set_or_return(
          :physical_volumes,
          arg,
          :kind_of => [String, Array]
        )
      end

      def stripes(arg = nil)
        set_or_return(
          :stripes,
          arg,
          :kind_of => Integer,
          :callbacks => {
            'must be greater than 0' => Proc.new { |value| value > 0 }
          }
        )
      end

      def stripe_size(arg = nil)
        set_or_return(
          :stripe_size,
          arg,
          :kind_of => Integer,
          :callbacks => {
            'must be a power of 2' => Proc.new do |value|
              return Math.log2(value) % 1 == 0
            end
          }
        )
      end

      def mirrors(arg = nil)
        set_or_return(
          :mirrors,
          arg,
          :kind_of => Integer,
          :callbacks => {
            'must be greater than 0' => Proc.new { |value| value > 0 }
          }
        )
      end

      def contiguous(arg = nil)
        set_or_return(
          :contiguous,
          arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

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
