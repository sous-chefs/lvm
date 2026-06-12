# lvm_thin_volume

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Creates an LVM thin logical volume from a pre-existing thin pool. Thin volumes have a _virtual_ size that can exceed available VG free space (over-provisioning). Supports optional filesystem creation, LUKS encryption, and mount point management.

See also: [partial_lv_common](partial_lv_common.md), [partial_lv_filesystem](partial_lv_filesystem.md)

Introduced: v8.0.0

## Actions

| Action | Description |
| ------ | ----------- |
| `:create` | Create the thin volume if absent; optionally create filesystem and mount point (default) |
| `:resize` | Resize the thin volume's virtual size; grow filesystem if configured |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | String | _name property_ | Name of the thin logical volume |
| `group` | String | `nil` | Volume group the thin volume belongs to |
| `pool` | String | `nil` | Name of the thin pool to provision this volume from |
| `size` | String, Integer | `nil` | Virtual size (e.g. `"50G"`) — may exceed VG free space |
| `physical_volumes` | String, Array | `nil` | Restrict allocation to specific PVs within the VG |
| `wipe_signatures` | true, false | `false` | Wipe existing signatures before creation (`-W y`) |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped |
| `filesystem` | String | `nil` | Filesystem type (e.g. `"xfs"`, `"ext4"`, `"btrfs"`) |
| `filesystem_params` | String | `nil` | Additional flags passed verbatim to `mkfs` |
| `mount_point` | String, Hash | `nil` | Mount point path or Hash with `:location`, `:fstype`, `:options`, `:dump`, `:pass` |
| `encrypt_with_luks` | true, false | `false` | Encrypt the block device with LUKS before creating the filesystem |
| `luks_version` | String, Integer | `2` | LUKS format version: `1` or `2` |
| `password` | String | `nil` | Path to a key-file for LUKS `luksFormat` and `open` (sensitive) |

## Examples

Standalone thin volume:

```ruby
lvm_thin_volume 'datalv' do
  group      'datavg'
  pool       'thinpool'
  size       '50G'
  filesystem 'xfs'
  mount_point '/data'
end
```

Resize a thin volume:

```ruby
lvm_thin_volume 'datalv' do
  group  'datavg'
  pool   'thinpool'
  size   '100G'
  action :resize
end
```

Nested inside `lvm_thin_pool`:

```ruby
lvm_thin_pool 'thinpool' do
  group  'datavg'
  size   '20G'
  thin_volumes [
    lvm_thin_volume('vol1') { group 'datavg'; pool 'thinpool'; size '50G'; filesystem 'xfs'; mount_point '/data' },
  ]
end
```
