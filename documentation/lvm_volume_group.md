
# lvm_volume_group

[Back to resource list](../README.md#resources)

Manages LVM volume groups.

## Actions

| Action    | Description                                                     |
| --------- | --------------------------------------------------------------- |
| `:create` | (default) Creates a new volume group                            |
| `:extend` | Extend an existing volume group to include new physical volumes |

## Properties

| Name                    | Type            | Default       | Description                                                                                                                                                                |
| ----------------------- | --------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vg_name`               | String          | name property | Name of the volume group                                                                                                                                                   |
| `physical_volumes`      | String, Array   |               | (required) The device or list of devices to use as physical volumes (if they haven't already been initialized as physical volumes, they will be initialized automatically) |
| `physical_extent_size`  | String          | `nil`         | Physical extent size for the volume group (e.g. `4M`). Must match pattern `\d+[kKmMgGtT]?`                                                                                 |
| `wipe_signatures`       | `true`, `false` | `false`       | Whether to automatically wipe signatures on new PVs                                                                                                                        |
| `ignore_skipped_cluster`| `true`, `false` | `false`       | Whether to ignore skipped cluster VGs during LVM commands                                                                                                                  |

## DSL Methods

### `logical_volume`

Shortcut DSL method for declaring nested `lvm_logical_volume` resources within a volume group block. Logical volumes are created in the order they are declared.

### `thin_pool` _(via nested `lvm_thin_pool`)_

Nested `lvm_thin_pool` resources should be declared using `lvm_thin_pool` directly or via the `logical_volume` DSL inside `lvm_volume_group`. Thin pools declared as nested `lvm_thin_pool` resources inside the volume group will be processed automatically.

## Examples

```ruby
lvm_volume_group 'vg00' do
  physical_volumes ['/dev/sda', '/dev/sdb', '/dev/sdc']
  wipe_signatures true

  logical_volume 'logs' do
    size        '1G'
    filesystem  'xfs'
    mount_point location: '/var/log', options: 'noatime,nodiratime'
    stripes     3
  end

  logical_volume 'home' do
    size        '25%VG'
    filesystem  'ext4'
    mount_point '/home'
    stripes     3
    mirrors     2
  end
end

lvm_volume_group 'vg01' do
  physical_volumes '/dev/sdd'
  action :extend
end
```
