# lvm_thin_pool

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Creates an LVM thin pool logical volume. Thin volumes provisioned from this pool are managed via [`lvm_thin_volume`](lvm_thin_volume.md). Uses `lvcreate --thin` directly with `lvm lvs --reportformat json` for idempotency — no gem dependencies.

See also: [partial_lv_common](partial_lv_common.md)

Introduced: v8.0.0

## Actions

| Action | Description |
| ------ | ----------- |
| `:create` | Create the thin pool if absent; create any nested thin volumes (default) |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | String | _name property_ | Name of the thin pool logical volume |
| `group` | String | `nil` | Volume group the thin pool belongs to |
| `size` | String, Integer | `nil` | Size of the pool data area (e.g. `"20G"`, `"50%FREE"`) |
| `take_up_free_space` | true, false | `false` | Use `100%FREE`; overrides `size` |
| `stripes` | Integer | `nil` | Number of stripes for the thin pool data area |
| `stripe_size` | Integer | `nil` | Stripe size in KB |
| `metadata_size` | String, Integer | `nil` | Override thin pool metadata volume size at creation time (e.g. `"4M"`, `"1G"`). For post-creation growth use [`lvm_thin_pool_meta`](lvm_thin_pool_meta.md) |
| `chunksize` | String, Integer | `nil` | Size of data chunks in the thin pool (e.g. `"64k"`, `"256k"`) |
| `zero` | true, false | `true` | Zero out newly allocated data blocks. Set `false` for better write performance when data initialisation is not required |
| `thin_volumes` | Array | `[]` | Array of `lvm_thin_volume` resource objects to create in this pool after the pool itself is created |
| `physical_volumes` | String, Array | `nil` | Restrict allocation to specific PVs within the VG |
| `wipe_signatures` | true, false | `false` | Wipe existing signatures before creation (`-W y`) |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped |

## Examples

Simple thin pool:

```ruby
lvm_thin_pool 'thinpool' do
  group 'datavg'
  size  '20G'
end
```

Thin pool using all free space:

```ruby
lvm_thin_pool 'thinpool' do
  group             'datavg'
  take_up_free_space true
end
```

Thin pool with nested thin volumes:

```ruby
lvm_thin_pool 'thinpool' do
  group  'datavg'
  size   '20G'
  thin_volumes [
    lvm_thin_volume('vol1') { group 'datavg'; pool 'thinpool'; size '50G'; filesystem 'xfs'; mount_point '/data1' },
    lvm_thin_volume('vol2') { group 'datavg'; pool 'thinpool'; size '30G'; filesystem 'ext4'; mount_point '/data2' },
  ]
end
```

Thin pool with custom chunk size and explicit metadata size:

```ruby
lvm_thin_pool 'thinpool' do
  group         'datavg'
  size          '100G'
  chunksize     '512k'
  metadata_size '1G'
  zero          false
end
```
