# frozen_string_literal: true

provides :lvm_logical_volume
unified_mode true

use '_partial/_logical_volume'

property :name, String,
         name_property: true,
         description: 'Name of the logical volume',
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
         description: 'Size of the logical volume (e.g. 10G, 512M, 100%FREE, 50%VG)',
         regex: /^(\d+[kKmMgGtTpPeE]|(\d{1,2}|100)%(FREE|VG|PVS)|\d+)$/

property :physical_volumes, [String, Array],
         description: 'Physical volume(s) to place this logical volume on'

property :stripes, Integer,
         description: 'Number of stripes',
         callbacks: { 'must be greater than 0' => proc { |v| v > 0 } }

property :stripe_size, Integer,
         description: 'Size of each stripe in KB (must be a power of 2)',
         callbacks: { 'must be a power of 2' => proc { |v| (Math.log2(v) % 1).zero? } }

property :mirrors, Integer,
         description: 'Number of mirrors',
         callbacks: { 'must be greater than 0' => proc { |v| v > 0 } }

property :contiguous, [true, false],
         description: 'Whether to use contiguous allocation'

property :readahead, [Integer, String],
         description: 'Read-ahead sector count (2-120, "auto", or "none")',
         equal_to: [*2..120, 'auto', 'none']

property :take_up_free_space, [true, false],
         description: 'Whether to extend the logical volume to consume all free space in the VG'

property :wipe_signatures, [true, false],
         default: false,
         description: 'Whether to automatically wipe any preexisting signatures'

property :ignore_skipped_cluster, [true, false],
         default: false,
         description: 'Whether to pass --ignoreskippedcluster to LVM commands'

property :remove_mount_point, [true, false],
         description: 'Whether to remove the mount point directory on :remove'

default_action :create

action :create do
  lv_create_action(create_command)
end

action :resize do
  lv_resize_action
end

action :remove do
  lv_remove_action
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end

  def create_command
    size = case new_resource.size
           when /\d+[kKmMgGtT]/               then "--size #{new_resource.size}"
           when /(\d{1,2}|100)%(FREE|VG|PVS)/ then "--extents #{new_resource.size}"
           when /(\d+)/ then "--extents #{new_resource.size}"
           end

    stripes     = new_resource.stripes     ? "--stripes #{new_resource.stripes}"        : ''
    stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
    mirrors     = new_resource.mirrors     ? "--mirrors #{new_resource.mirrors}"        : ''
    contiguous  = new_resource.contiguous  ? '--contiguous y'                           : ''
    readahead   = new_resource.readahead   ? "--readahead #{new_resource.readahead}"    : ''
    yes_flag    = new_resource.wipe_signatures ? '--yes' : '-qq'
    lv_params   = new_resource.lv_params.to_s
    pvs         = [new_resource.physical_volumes].flatten.join(' ') if new_resource.physical_volumes

    "lvcreate #{size} #{stripes} #{stripe_size} #{mirrors} #{contiguous} #{readahead} #{lv_params} --name #{new_resource.name} #{new_resource.group} #{pvs} #{yes_flag}"
  end

  def resize_command(lv_size_req)
    device_name = "/dev/mapper/#{to_dm_name(new_resource.group)}-#{to_dm_name(new_resource.name)}"
    resize_fs   = /raw/i.match?(new_resource.filesystem.to_s) ? '' : '--resizefs'
    stripes     = new_resource.stripes     ? "--stripes #{new_resource.stripes}"        : ''
    stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
    mirrors     = new_resource.mirrors     ? "--mirrors #{new_resource.mirrors}"        : ''
    lv_params   = new_resource.lv_params.to_s

    "lvextend -l #{lv_size_req} #{resize_fs} #{stripes} #{stripe_size} #{mirrors} #{device_name} #{lv_params}"
  end

  def remove_command
    device_name = "/dev/mapper/#{to_dm_name(new_resource.group)}-#{to_dm_name(new_resource.name)}"
    "lvremove #{device_name} #{new_resource.lv_params} --force"
  end
end
