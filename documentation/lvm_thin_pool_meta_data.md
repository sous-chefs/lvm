
# lvm_thin_pool_meta_data

[Back to resource list](../README.md#resources)

Manages LVM thin pool metadata volume size. This resource resizes the internal metadata logical volume of an existing thin pool.

## Actions

| Action    | Description                                                                                                                                                            |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:resize` | (default) Resize an existing thin pool metadata volume (resizing only handles extending; this action will not shrink volumes)                                          |

## Properties

| Name                     | Type           | Default       | Description                                                                                                  |
| ------------------------ | -------------- | ------------- | ------------------------------------------------------------------------------------------------------------ |
| `lv_name`                | String         | name property | Name of the thin pool metadata logical volume                                                                |
| `group`                  | String         | `nil`         | Name of the volume group in which the thin pool resides                                                      |
| `pool`                   | String         |               | (required) Name of the thin pool logical volume whose metadata will be resized                               |
| `size`                   | String         |               | (required) New size for the metadata volume, including units (`k`, `K`, `m`, `M`, `g`, `G`, `t`, `T`)        |
| `lv_params`              | String         | `nil`         | Additional parameters to pass to `lvextend`                                                                  |
| `filesystem`             | String         | `nil`         | File system type (kept for interface compatibility; unused for metadata volumes)                             |
| `filesystem_params`      | String         | `nil`         | Additional mkfs parameters (kept for interface compatibility; unused for metadata volumes)                   |
| `mount_point`            | String, Hash   | `nil`         | Mount point (kept for interface compatibility; unused for metadata volumes)                                  |
| `ignore_skipped_cluster` | `true`, `false`| `false`       | Whether to ignore skipped cluster VGs during LVM commands                                                    |

## Examples

```ruby
lvm_thin_pool_meta_data 'lv-thin-pool_tmeta' do
  group  'vg00'
  pool   'lv-thin-pool'
  size   '2M'
end
```
