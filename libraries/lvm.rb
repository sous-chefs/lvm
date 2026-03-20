# frozen_string_literal: true

#
# Copyright:: Chef Software, Inc.
# License:: Apache License, Version 2.0
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

module LVMCookbook
  LVM_GEM_VERSION = '0.4.0'
  LVM_ATTRIB_GEM_VERSION = '0.5.0'

  def require_lvm_gems
    return if defined?(LVM)

    gem 'chef-ruby-lvm-attrib', LVM_ATTRIB_GEM_VERSION
    gem 'chef-ruby-lvm', LVM_GEM_VERSION
    require 'lvm'
    Chef::Log.debug("Node had chef-ruby-lvm-attrib #{LVM_ATTRIB_GEM_VERSION} and chef-ruby-lvm #{LVM_GEM_VERSION} installed. No need to install gems.")
  rescue LoadError
    Chef::Log.debug('Did not find lvm gems of the specified versions installed. Installing now')

    rubygems_url = Chef::Config['rubygems_url']

    chef_gem 'chef-ruby-lvm-attrib' do
      action :install
      version LVM_ATTRIB_GEM_VERSION
      source rubygems_url
      clear_sources true
      compile_time true
    end

    chef_gem 'chef-ruby-lvm' do
      action :install
      version LVM_GEM_VERSION
      source rubygems_url
      clear_sources true
      compile_time true
    end

    require 'lvm'
  end
end
