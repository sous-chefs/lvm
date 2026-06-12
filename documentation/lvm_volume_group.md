# lvm_volume_group

Manages LVM volume groups (VGs). Can optionally declare logical volumes and thin pools
inline using DSL block helpers.

## Actions

| Action | Description |
|---|---|
| `:create` | Creates the VG (and any declared LVs) if it does not already exist |
| `:extend` | Extends the VG with additional PVs and resizes any declared LVs |

## Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | name | Name of the volume group |
| `physical_volumes` | `[String, Array]` | — | **Required.** PV device path(s) |
| `physical_extent_size` | `String` | — | PE size (e.g. `4m`, `8m`) |
| `wipe_signatures` | `[true, false]` | `false` | Pass `--yes` to vgcreate |
| `ignore_skipped_cluster` | `[true, false]` | `false` | Pass `--ignoreskippedcluster` |

## DSL Helpers

### `logical_volume(name, &block)`

Declares an `lvm_logical_volume` to create/resize when the VG action runs.

### `thin_pool(name, &block)`

Declares an `lvm_thin_pool` to create/resize when the VG action runs.

## Examples

```ruby
lvm_volume_group 'vg_data' do
  physical_volumes ['/dev/sdb', '/dev/sdc']
  physical_extent_size '4m'
end

lvm_volume_group 'vg_app' do
  physical_volumes '/dev/sdd'

  logical_volume 'lv_app' do
    size        '50G'
    filesystem  'xfs'
    mount_point '/srv/app'
  end

  thin_pool 'pool0' do
    size '20G'
    thin_volume 'tv_docker' do
      size '15G'
    end
  end
end
```
