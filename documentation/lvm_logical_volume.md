# lvm_logical_volume

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Creates, resizes, or manages an LVM logical volume. Supports optional filesystem creation, LUKS encryption, and mount point management. Uses `lvcreate`/`lvresize` directly with `lvm lvs --reportformat json` for idempotency — no gem dependencies.

See also: [partial_lv_common](partial_lv_common.md), [partial_lv_filesystem](partial_lv_filesystem.md)

Introduced: v8.0.0

## Actions

| Action | Description |
| ------ | ----------- |
| `:create` | Create the logical volume if absent; optionally create filesystem and mount point (default) |
| `:resize` | Resize the logical volume to the specified size; grow filesystem if configured |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | String | _name property_ | Name of the logical volume |
| `group` | String | `nil` | Volume group the logical volume belongs to |
| `size` | String, Integer | `nil` | Size (e.g. `"10G"`, `"512M"`, `"80%FREE"`, `"50%VG"`) |
| `take_up_free_space` | true, false | `false` | Use `100%FREE`; overrides `size` |
| `thin` | true, false | `false` | Create as a thin logical volume provisioned from a thin pool |
| `pool` | String | `nil` | Thin pool name (requires `thin: true`) |
| `physical_volumes` | String, Array | `nil` | Restrict allocation to specific PVs within the VG |
| `stripes` | Integer | `nil` | Number of stripes |
| `stripe_size` | Integer | `nil` | Stripe size in KB |
| `mirrors` | Integer | `nil` | Number of mirrors |
| `nosync` | true, false | `false` | Skip initial mirror synchronisation (`--nosync`) |
| `contiguous` | true, false | `false` | Require contiguous allocation (`--contiguous y`) |
| `readahead` | String, Integer | `nil` | Read-ahead sector count (`--readahead`) |
| `lv_params` | String | `''` | Arbitrary extra flags appended verbatim to `lvcreate` |
| `wipe_signatures` | true, false | `false` | Wipe existing signatures on the device before creation (`-W y`) |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped |
| `filesystem` | String | `nil` | Filesystem type (e.g. `"xfs"`, `"ext4"`, `"btrfs"`) |
| `filesystem_params` | String | `nil` | Additional flags passed verbatim to `mkfs` |
| `mount_point` | String, Hash | `nil` | Mount point path or Hash with `:location`, `:fstype`, `:options`, `:dump`, `:pass` |
| `encrypt_with_luks` | true, false | `false` | Encrypt the block device with LUKS before creating the filesystem |
| `luks_version` | String, Integer | `2` | LUKS format version: `1` or `2` |
| `password` | String | `nil` | Path to a key-file for LUKS `luksFormat` and `open` (sensitive) |

## Examples

Simple logical volume:

```ruby
lvm_logical_volume 'datalv' do
  group      'datavg'
  size       '10G'
end
```

With filesystem and mount point:

```ruby
lvm_logical_volume 'datalv' do
  group       'datavg'
  size        '20G'
  filesystem  'xfs'
  mount_point '/data'
end
```

Use all remaining free space:

```ruby
lvm_logical_volume 'datalv' do
  group             'datavg'
  take_up_free_space true
  filesystem        'ext4'
  mount_point       '/data'
end
```

Resize an existing volume:

```ruby
lvm_logical_volume 'datalv' do
  group  'datavg'
  size   '30G'
  action :resize
end
```

Striped volume:

```ruby
lvm_logical_volume 'stripelv' do
  group       'datavg'
  size        '40G'
  stripes     2
  stripe_size 64
end
```

LUKS-encrypted volume:

```ruby
lvm_logical_volume 'secretlv' do
  group            'datavg'
  size             '10G'
  encrypt_with_luks true
  password         '/etc/lvm/keyfile'
  filesystem       'ext4'
  mount_point      '/secret'
end
```
