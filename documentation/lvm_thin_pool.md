
# lvm_thin_pool

[Back to resource list](../README.md#resources)

Manages LVM thin pools (which are simply logical volumes created with the `--thinpool` argument to `lvcreate`).

## Actions

| Action    | Description                                                                                                                                                            |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:create` | (default) Create a new thin pool logical volume                                                                                                                        |
| `:resize` | Resize an existing thin pool logical volume (resizing only handles extending existing, this action will not shrink volumes due to the `lvextend` command being passed) |

## Properties

| Name                 | Type            | Default       | Description                                                                                                                              |
| -------------------- | --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `name`               | String          | name property | Name of the logical volume                                                                                                               |
| `group`              | String          |               | (required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block) |
| `size`               | String          |               | (required) Size of the thin pool volume, including units (k, K, m, M, g, G, t, T) or as the percentage of the size of the volume group   |
| `filesystem`         | String          | `nil`         | The format for the file system                                                                                                           |
| `filesystem_params`  | String          | `nil`         | Optional parameters to use when formatting the file system                                                                               |
| `mount_point`        | String, Hash    | `nil`         | Either a String containing the path to the mount point, or a Hash                                                                        |
| `physical_volumes`   | String, Array   | `[]`          | Array of physical volumes that the volume will be restricted to                                                                          |
| `stripes`            | Integer         | `nil`         | Number of stripes for the volume                                                                                                         |
| `stripe_size`        | Integer         | `nil`         | Number of kilobytes per stripe segment (must be a power of 2 less than or equal to the physical extent size for the volume group)        |
| `mirrors`            | Integer         | `nil`         | Number of mirrors for the volume                                                                                                         |
| `contiguous`         | `true`, `false` | `false`       | Whether or not volume should use the contiguous allocation policy                                                                        |
| `readahead`          | Integer, String | `nil`         | The readahead sector count for the volume (can be a value between 2 and 120, 'auto', or 'none')                                          |
| `take_up_free_space` | `true`, `false` | `false`       | whether to have the LV take up the remainder of free space on the VG. Only valid for resize action                                       |
| `thin_volume`        | Proc            | `nil`         | Shortcut for creating a new `lvm_thin_volume` definition (the volumes will be created in the order they are declared)                    |

### mount_point

If using a Hash, it _must_ contain the following keys:

- `location` - (required) the directory to mount the volume on
- `options` - the mount options for the volume
- `dump` - the dump field for the fstab entry
- `pass` - the pass field for the fstab entry

## Examples

```ruby
lvm_thin_pool 'home' do
  group       'vg00'
  size        '25%VG'
  filesystem  'ext4'
  mount_point '/home'
  stripes     3
  mirrors     2
end
```
