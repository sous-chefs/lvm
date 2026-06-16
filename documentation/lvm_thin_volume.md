
# lvm_thin_volume

[Back to resource list](../README.md#resources)

Manages LVM thin volumes (logical volumes created with `--thin` inside a thin pool created with `--thinpool`).

## Actions

| Action    | Description                                                                                                                                                       |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:create` | (default) Create a new thin logical volume                                                                                                                        |
| `:resize` | Resize an existing thin logical volume (resizing only handles extending; this action will not shrink volumes)                                                     |

## Properties

| Name                     | Type           | Default       | Description                                                                                                                               |
| ------------------------ | -------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `lv_name`                | String         | name property | Name of the thin logical volume                                                                                                           |
| `group`                  | String         | `nil`         | Volume group in which the thin pool resides (not required if declared inside an `lvm_thin_pool` block)                                    |
| `pool`                   | String         |               | (required) Name of the thin pool logical volume in which this thin volume will be created                                                 |
| `size`                   | String         |               | (required) Virtual size of the thin volume, including units (`k`, `K`, `m`, `M`, `g`, `G`, `t`, `T`) — percentage sizes are not supported |
| `filesystem`             | String         | `nil`         | File system type to format the volume with (e.g. `ext4`, `xfs`)                                                                          |
| `filesystem_params`      | String         | `nil`         | Additional parameters to pass to `mkfs` when formatting                                                                                   |
| `mount_point`            | String, Hash   | `nil`         | Either a String path to mount the volume on, or a Hash (see below)                                                                        |
| `lv_params`              | String         | `nil`         | Additional parameters to pass to `lvcreate`                                                                                               |
| `ignore_skipped_cluster` | `true`, `false`| `false`       | Whether to ignore skipped cluster VGs during LVM commands                                                                                 |

### mount_point

If using a Hash, it _must_ contain the following keys:

- `location` - (required) the directory to mount the volume on
- `options` - the mount options for the volume
- `dump` - the dump field for the fstab entry
- `pass` - the pass field for the fstab entry

## Examples

```ruby
lvm_thin_volume 'thin01' do
  group       'vg00'
  pool        'lv-thin-pool'
  size        '5G'
  filesystem  'ext4'
  mount_point location: '/var/thin01', options: 'noatime,nodiratime'
end

lvm_thin_volume 'thin02' do
  group  'vg00'
  pool   'lv-thin-pool'
  size   '20G'
  action :resize
end
```
