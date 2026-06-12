# lvm_thin_pool_meta

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Manages the metadata volume of an existing LVM thin pool. LVM auto-creates a `[pool_tmeta]` internal LV when a thin pool is created; this resource lets you grow it post-creation and control the pool metadata spare.

> **Note:** Use the `metadata_size` property on [`lvm_thin_pool`](lvm_thin_pool.md) to set metadata size _at creation time_. This resource is for post-creation growth only — LVM does not support shrinking pool metadata.

See also: [partial_lv_common](partial_lv_common.md)

Introduced: v8.0.0

## Actions

| Action | Description |
| ------ | ----------- |
| `:create` | Extend metadata volume to at least `size`; set pool metadata spare preference (default) |
| `:resize` | Alias for `:create` — same logic, kept for API consistency |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | String | _name property_ | Name of the thin pool whose metadata volume to manage (matches the `lvm_thin_pool` resource name) |
| `group` | String | `nil` | Volume group the thin pool belongs to |
| `size` | String, Integer | _required_ | Target size for the metadata volume (e.g. `"512M"`, `"1G"`, `1073741824`). Only growth is applied |
| `persist` | true, false | `true` | Enable the LVM pool metadata spare volume (`lvchange --poolmetadataspare y/n`). Strongly recommended in production |
| `contiguous` | true, false | `false` | Require contiguous allocation for the metadata extension (`--contiguous y`) |
| `readahead` | String, Integer | `'auto'` | Read-ahead sector count for the metadata volume (`--readahead`) |
| `stripes` | Integer | `nil` | Number of stripes for the metadata extension |
| `stripe_size` | Integer | `nil` | Stripe size in KB for the metadata extension |
| `physical_volumes` | String, Array | `nil` | Restrict allocation to specific PVs within the VG |
| `wipe_signatures` | true, false | `false` | Wipe existing signatures before creation (`-W y`) |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped |

## Examples

Ensure metadata is at least 512 MiB:

```ruby
lvm_thin_pool_meta 'thinpool' do
  group 'datavg'
  size  '512M'
end
```

Grow metadata to 1 GiB and disable the metadata spare:

```ruby
lvm_thin_pool_meta 'thinpool' do
  group   'datavg'
  size    '1G'
  persist false
end
```
