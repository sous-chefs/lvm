# lvm_thin_volume

Manages thin logical volumes within an LVM thin pool.

## Actions

| Action | Description |
|---|---|
| `:create` | Creates the thin volume (virtually-allocated) |
| `:resize` | Extends the thin volume |

## Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | name | Name of the thin volume |
| `group` | `String` | — | Volume group name |
| `pool` | `String` | — | **Required.** Thin pool LV name |
| `size` | `String` | — | **Required.** Virtual size (e.g. `10G`, `512M`) |
| `filesystem` | `String` | — | Filesystem type |
| `filesystem_params` | `String` | — | Extra mkfs parameters |
| `mount_point` | `[String, Hash]` | — | Mount path or options hash |
| `lv_params` | `String` | — | Extra lvcreate flags |
| `ignore_skipped_cluster` | `[true, false]` | `false` | Pass `--ignoreskippedcluster` |

## Examples

```ruby
lvm_thin_volume 'tv_app' do
  group      'vg_data'
  pool       'pool0'
  size       '20G'
  filesystem 'xfs'
  mount_point '/srv/app'
end
```
