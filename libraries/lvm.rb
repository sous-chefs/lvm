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
  LVM_GEM_VERSION = '0.4.3'
  LVM_ATTRIB_GEM_VERSION = '0.6.0'

  def lvm_gem_version
    node.dig('lvm', 'chef-ruby-lvm-version') || LVM_GEM_VERSION
  end

  def lvm_attrib_gem_version
    node.dig('lvm', 'chef-ruby-lvm-attrib-version') || LVM_ATTRIB_GEM_VERSION
  end

  def require_lvm_gems
    return if defined?(LVM)

    gem 'chef-ruby-lvm-attrib', lvm_attrib_gem_version
    gem 'chef-ruby-lvm', lvm_gem_version
    require 'lvm'
    patch_lvm_version_parsing
    Chef::Log.debug("Node had chef-ruby-lvm-attrib #{lvm_attrib_gem_version} and chef-ruby-lvm #{lvm_gem_version} installed. No need to install gems.")
  rescue LoadError
    Chef::Log.debug('Did not find lvm gems of the specified versions installed. Installing now')

    rubygems_url = Chef::Config['rubygems_url']

    chef_gem 'chef-ruby-lvm-attrib' do
      action :install
      version lvm_attrib_gem_version
      source rubygems_url
      clear_sources true
      compile_time true
    end

    chef_gem 'chef-ruby-lvm' do
      action :install
      version lvm_gem_version
      source rubygems_url
      clear_sources true
      compile_time true
    end

    require 'lvm'
    patch_lvm_version_parsing
  end

  # Workaround for chef-ruby-lvm version parsing bug. On RHEL-based distros the
  # LVM version string includes a distro suffix inside the parentheses, e.g.
  # "2.03.32(2-RHEL10)". The upstream regex ^(.*?)(-| ) captures "2.03.32(2"
  # (stopping at the first hyphen), which doesn't match any attributes directory.
  # This patch extracts the base version with numeric paren suffix, e.g.
  # "2.03.32(2-RHEL10)" becomes "2.03.32(2)".
  # TODO: Remove once chef-ruby-lvm is fixed upstream
  def patch_lvm_version_parsing
    return if LVM::LVM.method_defined?(:_lvm_cookbook_version_patched)

    LVM::LVM.class_eval do
      def version
        ver_str = userland.lvm_version
        match = ver_str.match(/^([\d.]+)\((\d+)[^)]*\)/)
        match ? "#{match[1]}(#{match[2]})" : ver_str.split(/[-\s]/).first
      end

      def _lvm_cookbook_version_patched
        true
      end
    end
  end
end
