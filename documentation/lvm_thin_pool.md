
# lvm_thin_pool

[Back to resource list](../README.md#resources)

Manages LVM thin pools (logical volumes created with the `--thinpool` argument to `lvcreate`).

## Actions

| Action    | Description                                                                                                                                                            |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:create` | (default) Create a new thin pool logical volume                                                                                                                        |
| `:resize` | Resize an existing thin pool logical volume (resizing only handles extending; this action will not shrink volumes)                                                     |

## Properties

| Name                     | Type            | Default       | Description                                                                                                                              |
| ------------------------ | --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `lv_name`                | String          | name property | Name of the thin pool logical volume                                                                                                     |
| `group`                  | String          | `nil`         | Volume group in which to create the thin pool (not required if declared inside an `lvm_volume_group` block)                              |
| `size`                   | String          | `nil`         | Size of the thin pool, including units (`k`, `K`, `m`, `M`, `g`, `G`, `t`, `T`) or as a percentage of the volume group (e.g. `25%VG`)    |
| `filesystem`             | String          | `nil`         | File system type to format the volume with (e.g. `ext4`, `xfs`)                                                                          |
| `filesystem_params`      | String          | `nil`         | Additional parameters to pass to `mkfs` when formatting                                                                                  |
| `mount_point`            | String, Hash    | `nil`         | Either a String path to mount the volume on, or a Hash (see below)                                                                       |
| `lv_params`              | String          | `nil`         | Additional parameters to pass to `lvcreate`/`lvextend`                                                                                   |
| `physical_volumes`       | String, Array   | `nil`         | Physical volume(s) to restrict the thin pool to                                                                                          |
| `stripes`                | Integer         | `nil`         | Number of stripes for the volume (must be greater than 0)                                                                                |
| `stripe_size`            | Integer         | `nil`         | Stripe size in kilobytes (must be a power of 2)                                                                                          |
| `mirrors`                | Integer         | `nil`         | Number of mirrors for the volume (must be greater than 0)                                                                                |
| `contiguous`             | `true`, `false` | `nil`         | Whether to use the contiguous allocation policy                                                                                          |
| `readahead`              | Integer, String | `nil`         | Read-ahead sector count (2–120, `'auto'`, or `'none'`)                                                                                   |
| `take_up_free_space`     | `true`, `false` | `nil`         | Whether the thin pool should take up the remainder of free space on the VG (only valid for `:resize` action)                             |
| `wipe_signatures`        | `true`, `false` | `false`       | Whether to automatically wipe any preexisting signatures when creating the volume                                                        |
| `ignore_skipped_cluster` | `true`, `false` | `false`       | Whether to ignore skipped cluster VGs during LVM commands                                                                                |

## DSL Methods

### `thin_volume`

Shortcut DSL method for declaring nested `lvm_thin_volume` resources within a thin pool block. Thin volumes are created in the order they are declared.

### mount_point

If using a Hash, it _must_ contain the following keys:

- `location` - (required) the directory to mount the volume on
- `options` - the mount options for the volume
- `dump` - the dump field for the fstab entry
- `pass` - the pass field for the fstab entry

## Examples

```ruby
lvm_thin_pool 'lv-thin-pool' do
  group   'vg00'
  size    '5G'
  stripes 2

  thin_volume 'thin01' do
    size        '10G'
    filesystem  'ext4'
    mount_point location: '/var/thin01', options: 'noatime,nodiratime'
  end
end

lvm_thin_pool 'lv-thin-pool' do
  group  'vg00'
  size   '10G'
  action :resize
end
```
