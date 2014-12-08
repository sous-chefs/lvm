#
# Cookbook Name:: lvm
# Resource:: logical_volume
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

actions :create, :resize
default_action :create

attribute :name, kind_of: String, regex: /[\w+.-]+/, name_attribute: true, required: true, callbacks: {
  "cannot be '.', '..', 'snapshot', or 'pvmove'" => proc do |value|
    !(value == '.' || value == '..' || value == 'snapshot' || value == 'pvmove')
  end,
  "cannot contain the strings '_mlog' or '_mimage'" => proc do |value|
    !value.match(/.*(_mlog|_mimage).*/)
  end
}
attribute :group,  kind_of: String
attribute :size, kind_of: String, regex: /^(\d+[kKmMgGtTpPeE]|(\d{1,2}|100)%(FREE|VG|PVS)|\d+)$/, required: true
attribute :filesystem, kind_of: String
attribute :mount_point, kind_of: [String, Hash], callbacks: {
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
attribute :physical_volumes, kind_of: [String, Array]
attribute :stripes, kind_of: Integer, callbacks: { 'must be greater than 0' => proc { |value| value > 0 } }
attribute :stripe_size, kind_of: Integer, callbacks: { 'must be a power of 2' => proc { |value| Math.log2(value) % 1 == 0 } }
attribute :mirrors, kind_of: Integer, callbacks: { 'must be greater than 0' => proc { |value| value > 0 } }
attribute :contiguous, kind_of: [TrueClass, FalseClass]
attribute :readahead, kind_of: [Integer, String], equal_to: [2..120, 'auto', 'none'].flatten!
attribute :take_up_free_space, kind_of: [TrueClass, FalseClass]
