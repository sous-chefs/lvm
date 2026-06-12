# frozen_string_literal: true
#
# Cookbook:: lvm
# Resource:: thin_pool
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
# Creates an LVM thin pool logical volume.
# Thin volumes provisioned from this pool are managed via lvm_thin_volume.

unified_mode true

use 'partial/_lv_common' # group, size, physical_volumes, wipe_signatures, ignore_skipped_cluster

# ----------------------------------------------------------------------------
# Resource-specific properties
# ----------------------------------------------------------------------------

property :name, String, name_property: true,
                        description: 'Name of the thin pool logical volume'

property :take_up_free_space, [true, false], default: false,
                                             description: 'Use 100%FREE instead of a fixed size'

property :stripes, Integer,
         description: 'Number of stripes for the thin pool data area'

property :stripe_size, Integer,
         description: 'Stripe size in KB'

property :metadata_size, [String, Integer],
         description: 'Override thin pool metadata volume size (e.g. "4M", "1G")'

property :chunksize, [String, Integer],
         description: 'Size of data chunks in the thin pool (e.g. "64k", "256k")'

property :zero, [true, false], default: true,
                               description: 'Zero out newly allocated data blocks (default: true). ' \
                      'Set false for slightly better write performance when data initialisation is not required.'

property :thin_volumes, Array, default: [],
                               coerce: proc { |v| Array(v) },
                               description: 'Array of lvm_thin_volume resource objects to create in this pool ' \
                      'after the pool itself is created'

# ----------------------------------------------------------------------------
# action_class helpers
# ----------------------------------------------------------------------------

action_class do
  include LvmActionHelpers

  def lv_key
    "#{new_resource.group}/#{new_resource.name}"
  end

  def thin_pool_exists?
    current_lvs.key?(lv_key)
  end

  def size_args
    if new_resource.take_up_free_space
      '-l 100%FREE'
    else
      s = new_resource.size
      raise "lvm_thin_pool '#{new_resource.name}' requires 'size' or 'take_up_free_space'" if s.nil?

      LvmHelper.relative_size?(s.to_s) ? "-l #{s}" : "-L #{s}"
    end
  end
end

# ----------------------------------------------------------------------------
# :create
# ----------------------------------------------------------------------------

action :create do
  raise 'lvm_thin_pool: group is required' if new_resource.group.nil?
  raise "Volume group '#{new_resource.group}' does not exist!" \
    unless current_vgs.key?(new_resource.group)

  validate_pvs_in_vg!(new_resource.physical_volumes, new_resource.group)

  unless thin_pool_exists?
    converge_by("Create thin pool #{lv_key}") do
      cmd  = "lvcreate --thin #{size_args}"
      cmd += " -i #{new_resource.stripes}"                     if new_resource.stripes
      cmd += " -I #{new_resource.stripe_size}"                 if new_resource.stripe_size
      cmd += " --poolmetadatasize #{new_resource.metadata_size}" if new_resource.metadata_size
      cmd += " --chunksize #{new_resource.chunksize}"          if new_resource.chunksize
      cmd += ' --zero n'                                       unless new_resource.zero
      cmd += ' -W y' if new_resource.wipe_signatures
      cmd += " -n #{new_resource.name} #{new_resource.group}"
      cmd += " #{new_resource.physical_volumes.join(' ')}" if new_resource.physical_volumes
      lvm_command(cmd)
    end
  end

  # Create any nested thin volumes declared via the thin_volumes property
  Array(new_resource.thin_volumes).each do |tv|
    tv.group new_resource.group
    tv.pool  new_resource.name
    tv.run_action(:create)
  end
end
