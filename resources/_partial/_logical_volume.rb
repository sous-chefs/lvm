# frozen_string_literal: true

# Shared properties for all logical-volume-family resources.
# Include in a resource with: use '_partial/_logical_volume'

property :group, String,
         description: 'Name of the volume group this logical volume belongs to'

property :lv_params, String,
         description: 'Additional parameters to pass to lvcreate/lvextend/lvremove'

property :filesystem, String,
         description: 'Filesystem type to format the logical volume with (e.g. ext4, xfs)'

property :filesystem_params, String,
         description: 'Additional parameters to pass to mkfs'

property :mount_point, [String, Hash],
         description: 'Mount point path or mount options hash (:location, :options, :dump, :pass)',
         callbacks: {
           'location is required' => proc { |v|
             v.is_a?(String) || (v[:location] && !v[:location].empty?)
           },
           'location must be an absolute path' => proc { |v|
             path = v.is_a?(String) ? v : v[:location]
             path.match?(%r{^/[^\0]*})
           },
         }
