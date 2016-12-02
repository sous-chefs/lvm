#
# Copyright:: 2016, Chef Software, Inc.
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
  def require_lvm_gems
    # require attribute specified gems
    gem 'di-ruby-lvm-attrib', node['lvm']['di-ruby-lvm-attrib']['version']
    gem 'di-ruby-lvm', node['lvm']['di-ruby-lvm']['version']
    require 'lvm'
    Chef::Log.debug("Node had di-ruby-lvm-attrib #{node['lvm']['di-ruby-lvm-attrib']['version']} and di-ruby-lvm #{node['lvm']['di-ruby-lvm']['version']} installed. No need to install gems.")
  rescue LoadError
    Chef::Log.debug('Did not find lvm gems of the specified versions installed. Installing now')

    chef_gem 'di-ruby-lvm-attrib' do
      action :install
      version node['lvm']['di-ruby-lvm-attrib']['version']
      compile_time true
    end

    chef_gem 'di-ruby-lvm' do
      action :install
      version node['lvm']['di-ruby-lvm']['version']
      compile_time true
    end

    require 'lvm'
  end
end
