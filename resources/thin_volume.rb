# frozen_string_literal: true

provides :lvm_thin_volume
unified_mode true

use '_partial/_logical_volume'

property :name, String,
         name_property: true,
         description: 'Name of the thin logical volume',
         regex: /[\w+.-]+/,
         callbacks: {
           "cannot be '.', '..', 'snapshot', or 'pvmove'" => proc { |v|
             !%w(. .. snapshot pvmove).include?(v)
           },
           "cannot contain '_mlog' or '_mimage'" => proc { |v|
             !v.match?(/_mlog|_mimage/)
           },
         }

property :size, String,
         required: true,
         description: 'Virtual size of the thin volume (e.g. 10G, 512M)',
         regex: /^(\d+[kKmMgGtT]|\d+)$/

property :pool, String,
         required: true,
         description: 'Name of the thin pool to create this thin volume in'

property :ignore_skipped_cluster, [true, false],
         default: false,
         description: 'Whether to pass --ignoreskippedcluster to LVM commands'

default_action :create

action :create do
  lv_create_action(create_command)
end

action :resize do
  lv_resize_action
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end

  def thin_volume?
    true
  end

  def create_command
    "lvcreate --virtualsize #{new_resource.size} #{new_resource.lv_params} --thin --name #{new_resource.name} #{new_resource.group}/#{new_resource.pool}"
  end

  def resize_command(lv_size_req)
    device_name = "/dev/mapper/#{to_dm_name(new_resource.group)}-#{to_dm_name(new_resource.name)}"
    "lvextend -l #{lv_size_req} --resizefs #{device_name}"
  end
end
