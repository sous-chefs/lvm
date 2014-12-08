#
# Cookbook Name:: lvm
# Resource:: volume_group
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

include Chef::DSL::Recipe

actions :create,  :extend
default_action :create

def initialize(name, run_context = nil)
  super
  @logical_volumes = []
end

attribute :name, kind_of: String, name_attribute: true, regex: /[\w+.-]+/, required: true, callbacks: {
  "cannot be '.' or '..'" => proc do |value|
    !(value == '.' || value == '..')
  end
}
attribute :physical_volumes, kind_of: [Array, String], required: true
attribute :physical_extent_size,  kind_of: String, regex: /\d+[bBsSkKmMgGtTpPeE]?/
attr_accessor :logical_volumes

# A shortcut for creating a logical volume when creating the volume group
#
# @param name [String] the name of the logical volume
# @param block [Proc] the block defining the lvm_logical_volume resource
#
# @return [Chef::Resource::LvmLogicalVolume] the lvm_logical_volume resource
#

def logical_volume(name, &block)
  Chef::Log.debug "Creating logical volume #{name}"
  volume = lvm_logical_volume(name, &block)
  volume.action :nothing
  @logical_volumes << volume
  volume
end
