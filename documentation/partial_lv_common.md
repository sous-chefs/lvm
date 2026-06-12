# partial_lv_common

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Shared properties included across all LVM logical volume resource types via `use 'partial/_lv_common'`.

Consumers: [`lvm_logical_volume`](lvm_logical_volume.md), [`lvm_thin_pool`](lvm_thin_pool.md), [`lvm_thin_pool_meta`](lvm_thin_pool_meta.md), [`lvm_thin_volume`](lvm_thin_volume.md)

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `group` | String | `nil` | Volume group the logical volume belongs to |
| `size` | String, Integer | `nil` | Size of the volume (e.g. `"10G"`, `"512M"`, `"80%FREE"`, `"50%VG"`). For thin volumes this is the virtual size and may exceed VG free space |
| `physical_volumes` | String, Array | `nil` | Restrict allocation to specific physical volumes within the VG |
| `wipe_signatures` | true, false | `false` | Wipe any existing signatures on the block device before creation (`-W y`) |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped during device scanning |
