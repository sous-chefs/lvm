# frozen_string_literal: true
#
# Cookbook:: lvm
# Resource:: volume_group
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
# Creates or extends an LVM volume group.
# No gem dependencies — uses `vgcreate`/`vgextend` directly and
# `lvm vgs --reportformat json` for idempotency checks.

unified_mode true

property :name, String, name_property: true,
                        description: 'Name of the volume group'

property :physical_volumes, [String, Array], required: true,
                                             coerce: proc { |v| Array(v) },
                                             description: 'One or more block devices to include in this VG'

property :physical_extent_size, [String, Integer],
         description: 'Physical extent size (e.g. "32m" or 32). Passed to vgcreate -s.'

property :logical_volumes, Array, default: [],
                                  description: 'Array of lvm_logical_volume resource objects to create inside this VG'

property :ignore_skipped_cluster, [true, false], default: false,
                                                 description: 'Ignore clustered VGs that are not active'

action_class do
  include LvmActionHelpers

  def vg_exists?
    current_vgs.key?(new_resource.name)
  end

  # Returns the set of PV names currently assigned to this VG
  def pvs_in_vg
    current_pvs.select { |_k, v| v['vg_name'] == new_resource.name }.keys
  end
end

# ----------------------------------------------------------------------------
# :create — create the VG if absent; add any PVs not yet in it if it exists;
#            then declare nested logical volumes.
# ----------------------------------------------------------------------------
action :create do
  if vg_exists?
    Chef::Log.debug("Volume group #{new_resource.name} already exists — checking PVs")

    # Auto-extend with any PVs not yet in this VG
    existing_pvs = pvs_in_vg
    new_resource.physical_volumes.each do |pv|
      next if existing_pvs.include?(pv)

      converge_by("Add physical volume #{pv} to volume group #{new_resource.name}") do
        lvm_command("vgextend #{new_resource.name} #{pv}")
      end
    end
  else
    converge_by("Create volume group #{new_resource.name}") do
      cmd = 'vgcreate'
      cmd += " -s #{new_resource.physical_extent_size}" if new_resource.physical_extent_size
      cmd += " #{new_resource.name} #{new_resource.physical_volumes.join(' ')}"
      lvm_command(cmd)
    end
  end

  # Declare any nested logical volumes (Array of lvm_logical_volume resources)
  Array(new_resource.logical_volumes).each do |lv|
    lv.group new_resource.name
    lv.run_action(:create)
  end
end

# ----------------------------------------------------------------------------
# :extend — add PVs to an already-existing VG (idempotent)
# ----------------------------------------------------------------------------
action :extend do
  raise "Volume group '#{new_resource.name}' does not exist!" unless vg_exists?

  existing_pvs = pvs_in_vg
  new_resource.physical_volumes.each do |pv|
    next if existing_pvs.include?(pv)

    converge_by("Add physical volume #{pv} to volume group #{new_resource.name}") do
      lvm_command("vgextend #{new_resource.name} #{pv}")
    end
  end
end
