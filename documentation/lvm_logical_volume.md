# lvm_logical_volume

Manages LVM logical volumes (LVs). Supports creating, resizing, and removing LVs
with optional filesystem formatting and mounting.

## Actions

| Action | Description |
|---|---|
| `:create` | Creates the LV, formats it, and mounts it (if configured) |
| `:resize` | Extends the LV to the requested size |
| `:remove` | Unmounts and removes the LV |

## Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | name | Name of the logical volume |
| `group` | `String` | — | Volume group name |
| `size` | `String` | — | **Required.** Size: `10G`, `512M`, `100%FREE`, `50%VG`, or raw extents |
| `filesystem` | `String` | — | Filesystem type for mkfs (e.g. `ext4`, `xfs`) |
| `filesystem_params` | `String` | — | Extra mkfs parameters |
| `mount_point` | `[String, Hash]` | — | Mount path or hash with `:location`, `:options`, `:dump`, `:pass` |
| `physical_volumes` | `[String, Array]` | — | Specific PVs to place the LV on |
| `stripes` | `Integer` | — | Number of stripes |
| `stripe_size` | `Integer` | — | Stripe size in KB (power of 2) |
| `mirrors` | `Integer` | — | Number of mirrors |
| `contiguous` | `[true, false]` | — | Use contiguous allocation |
| `readahead` | `[Integer, String]` | — | Read-ahead sectors (2-120, `auto`, `none`) |
| `take_up_free_space` | `[true, false]` | — | Extend to consume all free VG space |
| `wipe_signatures` | `[true, false]` | `false` | Pass `--yes` to lvcreate |
| `ignore_skipped_cluster` | `[true, false]` | `false` | Pass `--ignoreskippedcluster` |
| `remove_mount_point` | `[true, false]` | — | Remove mount point directory on `:remove` |
| `lv_params` | `String` | — | Extra flags passed to lvcreate/lvextend/lvremove |

## Examples

```ruby
lvm_logical_volume 'lv_data' do
  group      'vg_data'
  size       '20G'
  filesystem 'xfs'
  mount_point '/data'
end

lvm_logical_volume 'lv_logs' do
  group           'vg_data'
  size            '100%FREE'
  take_up_free_space true
  filesystem      'ext4'
  mount_point(location: '/var/log/app', options: 'defaults,noatime', dump: 0, pass: 2)
end

lvm_logical_volume 'lv_old' do
  group              'vg_data'
  size               '5G'
  mount_point        '/old'
  remove_mount_point true
  action :remove
end
```
