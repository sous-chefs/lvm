#
# Cookbook:: lvm
# Library:: matchers
#
# Copyright:: 2014-2017, Chef Software, Inc.
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

if defined?(ChefSpec)
  # Per the comment on https://github.com/sethvargo/chefspec/issues/241#issuecomment-26725772 runner_methods have to be defined
  # if this isn't done you cannot test if resource A notifies resource B
  %i(
    lvm_logical_volume
    lvm_physical_volume
    lvm_volume_group
    lvm_thin_pool
    lvm_thin_volume
  ).each do |method|
    ChefSpec.define_matcher method
  end

  def create_lvm_logical_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_logical_volume, :create, resource_name)
  end

  def resize_lvm_logical_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_logical_volume, :resize, resource_name)
  end

  def create_lvm_physical_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_physical_volume, :create, resource_name)
  end

  def resize_lvm_physical_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_physical_volume, :resize, resource_name)
  end

  def create_lvm_volume_group(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_volume_group, :create, resource_name)
  end

  def extend_lvm_volume_group(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_volume_group, :extend, resource_name)
  end

  def create_lvm_thin_pool(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_thin_pool, :create, resource_name)
  end

  def resize_lvm_thin_pool(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_thin_pool, :resize, resource_name)
  end

  def create_lvm_thin_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_thin_volume, :create, resource_name)
  end

  def resize_lvm_thin_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:lvm_thin_volume, :resize, resource_name)
  end
end
