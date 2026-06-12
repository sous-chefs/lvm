# frozen_string_literal: true
#
# Resource:: partial: properties shared across all LVM logical volume types.
# Loaded via `use 'partial/_lv_common'` in lvm_logical_volume, lvm_thin_pool, lvm_thin_pool_meta, lvm_thin_volume.
#
# NOT included here (too resource-specific):
#   take_up_free_space  — logical_volume + thin_pool only (meaningless for thin volumes)
#   stripes/stripe_size — set at pool level, not thin volume level
#   name                — always a name_property defined per-resource

property :group, String,
         description: 'Volume group the logical volume belongs to'

property :size, [String, Integer],
         description: 'Size of the volume (e.g. "10G", "512M", "80%FREE", "50%VG"). ' \
                      'For thin volumes this is the virtual size and may exceed VG free space.'

property :physical_volumes, [String, Array],
         coerce: proc { |v| Array(v) },
         description: 'Restrict allocation to specific physical volumes within the VG'

property :wipe_signatures, [true, false], default: false,
                                          description: 'Wipe any existing signatures on the block device before creation (-W y)'

property :ignore_skipped_cluster, [true, false], default: false,
                                                 description: 'Suppress errors when a clustered VG is skipped during device scanning'
