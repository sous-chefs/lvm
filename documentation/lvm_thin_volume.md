
# lvm_thin_volume

[Back to resource list](../README.md#resources)

Manages LVM thin volumes (which are simply logical volumes created with the `--thin` argument to `lvcreate` and are contained inside of other logical volumes that were created with the `--thinpool` option to `lvcreate`).

## Actions

| Action    | Description                                                                                                                                                       |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:create` | (default) Create a new thin logical volume                                                                                                                        |
| `:resize` | Resize an existing thin logical volume (resizing only handles extending existing, this action will not shrink volumes due to the `lvextend` command being passed) |

## Properties

| Name                | Type          | Default       | Description                                                                                                                               |
| ------------------- | ------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `name`              | String        | name property | Name of the logical volume                                                                                                                |
| `group`             | String        |               | (required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block)  |
| `pool`              | String        |               | (required) Thin pool volume in which to create the new volume (not required if the volume is declared inside of an `lvm_thin_pool` block) |
| `size`              | String        |               | (required) Size of the thin volume, including units (k, K, m, M, g, G, t, T)                                                              |
| `filesystem`        | String        | `nil`         | The format for the file system                                                                                                            |
| `filesystem_params` | String        | `nil`         | Optional parameters to use when formatting the file system                                                                                |
| `mount_point`       | String, Hash  | `nil`         | Either a String containing the path to the mount point, or a Hash                                                                         |

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
```
