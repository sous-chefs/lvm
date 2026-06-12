# frozen_string_literal: true
#
# Cookbook:: lvm
# Resource:: physical_volume
#
# Copyright:: 2024, Sous Chefs
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
# Creates or removes an LVM physical volume.
# No gem dependencies — uses `pvcreate`/`pvremove` directly and
# `lvm pvs --reportformat json` for idempotency checks.

unified_mode true

property :name, String, name_property: true,
                        description: 'Block device path (e.g. /dev/sdb)'

property :ignore_skipped_cluster, [true, false], default: false,
                                                 description: 'Ignore clustered VGs that are not active'

action_class do
  include LvmActionHelpers

  def pv_exists?
    current_pvs.key?(new_resource.name)
  end
end

# ----------------------------------------------------------------------------
# :create
# ----------------------------------------------------------------------------
action :create do
  if pv_exists?
    Chef::Log.debug("Physical volume #{new_resource.name} already exists — skipping")
  else
    converge_by("Create physical volume #{new_resource.name}") do
      lvm_command("pvcreate #{new_resource.name}")
    end
  end
end
