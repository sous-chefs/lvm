# frozen_string_literal: true

#
# Shared properties for logical volume resources (logical_volume, thin_pool,
# thin_volume, thin_pool_meta_data).
#

property :lv_name,
          String,
          name_property: true,
          description: 'Name of the logical volume'

property :group,
          String,
          description: 'Volume group name the logical volume belongs to'

property :lv_params,
          String,
          description: 'Additional parameters for lvcreate/lvextend'

property :size,
          String,
          regex: /^(\d+[kKmMgGtTpPeE]|(\d{1,2}|100)%(FREE|VG|PVS)|\d+)$/,
          description: 'Size of the logical volume'

property :filesystem,
          String,
          description: 'File system type (e.g. ext2, ext3, ext4, xfs)'

property :filesystem_params,
          String,
          description: 'Additional parameters for mkfs'

property :mount_point,
          [String, Hash],
          callbacks: {
            ': location is required!' => proc { |value|
              value.is_a?(String) || (value[:location] && !value[:location].empty?)
            },
            ': location must be an absolute path!' => proc { |value|
              case value
              when String
                value =~ %r{^/[^\0]*}
              when Hash
                value[:location] =~ %r{^/[^\0]*}
              end
            },
          },
          description: 'Mount point for the logical volume (String or Hash with :location, :options, :dump, :pass)'

property :ignore_skipped_cluster,
          [true, false],
          default: false,
          description: 'Whether to ignore skipped cluster VGs during LVM commands'
