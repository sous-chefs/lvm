
# lvm_logical_volume

[Back to resource list](../README.md#resources)

Manages LVM logical volumes.

## Actions

| Action    | Description                                                                                                                                                  |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `:create` | (default) Creates a new logical volume                                                                                                                       |
| `:resize` | Resize an existing logical volume (resizing only handles extending; this action will not shrink volumes)                                                     |
| `:remove` | Remove an existing logical volume (optionally clean up the mount location/directory)                                                                         |

## Properties

| Name                     | Type            | Default       | Description                                                                                                                              |
| ------------------------ | --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `lv_name`                | String          | name property | Name of the logical volume                                                                                                               |
| `group`                  | String          | `nil`         | Volume group in which to create the new volume (not required if declared inside an `lvm_volume_group` block)                             |
| `size`                   | String          | `nil`         | Size of the volume, including units (`k`, `K`, `m`, `M`, `g`, `G`, `t`, `T`) or as a percentage of the volume group (e.g. `25%VG`)     |
| `filesystem`             | String          | `nil`         | File system type to format the volume with (e.g. `ext4`, `xfs`)                                                                         |
| `filesystem_params`      | String          | `nil`         | Additional parameters to pass to `mkfs` when formatting the file system                                                                  |
| `mount_point`            | String, Hash    | `nil`         | Either a String path to mount the volume on, or a Hash (see below)                                                                       |
| `lv_params`              | String          | `nil`         | Additional parameters to pass to `lvcreate`/`lvextend`                                                                                  |
| `physical_volumes`       | String, Array   | `nil`         | Physical volume(s) to restrict the logical volume to                                                                                     |
| `stripes`                | Integer         | `nil`         | Number of stripes for the volume (must be greater than 0)                                                                                |
| `stripe_size`            | Integer         | `nil`         | Stripe size in kilobytes (must be a power of 2)                                                                                          |
| `mirrors`                | Integer         | `nil`         | Number of mirrors for the volume (must be greater than 0)                                                                                |
| `contiguous`             | `true`, `false` | `nil`         | Whether to use the contiguous allocation policy                                                                                          |
| `readahead`              | Integer, String | `nil`         | Read-ahead sector count (2–120, `'auto'`, or `'none'`)                                                                                   |
| `take_up_free_space`     | `true`, `false` | `nil`         | Whether the LV should take up the remainder of free space on the VG (only valid for `:resize` action)                                    |
| `wipe_signatures`        | `true`, `false` | `false`       | Whether to automatically wipe any preexisting signatures when creating the volume                                                        |
| `remove_mount_point`     | `true`, `false` | `nil`         | Whether to remove the mount directory when the `:remove` action is run                                                                   |
| `ignore_skipped_cluster` | `true`, `false` | `false`       | Whether to ignore skipped cluster VGs during LVM commands                                                                                |

### mount_point

If using a Hash, it _must_ contain the following keys:

- `location` - (required) the directory to mount the volume on
- `options` - the mount options for the volume
- `dump` - the dump field for the fstab entry
- `pass` - the pass field for the fstab entry

## Examples

```ruby
lvm_logical_volume 'home' do
  group       'vg00'
  size        '25%VG'
  filesystem  'ext4'
  mount_point '/home'
  stripes     3
  mirrors     2
end

lvm_logical_volume 'logs' do
  group            'vg00'
  size             '1G'
  filesystem       'xfs'
  mount_point      location: '/var/log', options: 'noatime,nodiratime'
  stripes          3
  lv_params        '--type striped'
end

lvm_logical_volume 'test' do
  group              'vg01'
  mount_point        '/mnt/test'
  remove_mount_point true
  action             :remove
end
```
