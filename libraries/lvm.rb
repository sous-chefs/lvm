#
# Copyright:: 2016-2017, Chef Software, Inc.
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
    return if defined?(LVM)

    Chef::Log.warn("The previous di-ruby-lvm and di-ruby-lvm-attrib gems have been replaced with chef maintained forks. You have set the legacy attributes (node['lvm']['di-ruby-lvm']/node['lvm']['di-ruby-lvm-attrib']) for pinning installed gem versions. You will need to remove these attributes and instead set the new chef varients. See the attributes file for the latest attributes.") if node['lvm']['di-ruby-lvm'] || node['lvm']['di-ruby-lvm-attrib']

    if node['lvm']['cleanup_old_gems']
      chef_gem "#{new_resource.name}_di-ruby-lvm-attrib_removal" do
        package_name 'di-ruby-lvm-attrib'
        action :remove
        compile_time true
        source node['lvm']['rubysource']
      end

      chef_gem "#{new_resource.name}_di-ruby-lvm_removal" do
        package_name 'di-ruby-lvm'
        action :remove
        compile_time true
        source node['lvm']['rubysource']
      end
    end

    # require attribute specified gems
    gem 'chef-ruby-lvm-attrib', node['lvm']['chef-ruby-lvm-attrib']['version']
    gem 'chef-ruby-lvm', node['lvm']['chef-ruby-lvm']['version']
    require 'lvm'
    Chef::Log.debug("Node had chef-ruby-lvm-attrib #{node['lvm']['chef-ruby-lvm-attrib']['version']} and chef-ruby-lvm #{node['lvm']['chef-ruby-lvm']['version']} installed. No need to install gems.")
  rescue LoadError
    Chef::Log.debug('Did not find lvm gems of the specified versions installed. Installing now')

    chef_gem 'chef-ruby-lvm-attrib' do
      action :install
      version node['lvm']['chef-ruby-lvm-attrib']['version']
      source node['lvm']['rubysource']
      clear_sources true
      compile_time true
    end

    chef_gem 'chef-ruby-lvm' do
      action :install
      version node['lvm']['chef-ruby-lvm']['version']
      source node['lvm']['rubysource']
      clear_sources true
      compile_time true
    end

    require 'lvm'
  end
end
