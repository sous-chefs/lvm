# partial_lv_filesystem

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Filesystem, mount-point, and LUKS encryption properties included in LVM resources that manage block devices via `use 'partial/_lv_filesystem'`.

Consumers: [`lvm_logical_volume`](lvm_logical_volume.md), [`lvm_thin_volume`](lvm_thin_volume.md)

> **Note:** `lvm_thin_pool` and `lvm_thin_pool_meta` intentionally do not include this partial — pool and metadata LVs never carry a filesystem or mount point.

## Filesystem grow behaviour

| Filesystem | Grow command | Notes |
| ---------- | ------------ | ----- |
| `ext2`/`ext3`/`ext4` | `resize2fs <device>` | Online; device path required. Deprecated on RHEL 10 |
| `xfs` | `xfs_growfs <mount_point>` | Online; **mount point** required (not device path). Cannot shrink. RHEL 10 default |
| `btrfs` | `btrfs filesystem resize max <mount_point>` | Online; mount point required. `lvresize --resizefs` does not support btrfs |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `filesystem` | String | `nil` | Filesystem type (e.g. `"xfs"`, `"ext4"`, `"btrfs"`). RHEL 10 default: `xfs` (ext4 deprecated). Ubuntu 26.04 default: `ext4` |
| `filesystem_params` | String | `nil` | Additional flags passed verbatim to `mkfs` (e.g. `"-L mylabel"`) |
| `mount_point` | String, Hash | `nil` | Mount point as an absolute path String, or a Hash with keys: `:location` (required), `:fstype`, `:options`, `:dump`, `:pass` |
| `encrypt_with_luks` | true, false | `false` | Encrypt the block device with LUKS before creating the filesystem |
| `luks_version` | String, Integer | `2` | LUKS format version: `1` or `2` |
| `password` | String | `nil` | Path to a key-file used for LUKS `luksFormat` and `open` (sensitive) |
