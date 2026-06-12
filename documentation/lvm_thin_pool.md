# lvm_thin_pool

Manages LVM thin-provisioning pool logical volumes. Can declare thin volumes inline.

## Actions

| Action | Description |
|---|---|
| `:create` | Creates the thin pool LV and any declared thin volumes |
| `:resize` | Extends the thin pool and resizes any declared thin volumes |
| `:remove` | Removes the thin pool LV |

## Properties

Same as `lvm_logical_volume` — see [lvm_logical_volume.md](lvm_logical_volume.md).

## DSL Helpers

### `thin_volume(name, &block)`

Declares an `lvm_thin_volume` to create/resize when the thin pool action runs.

## Examples

```ruby
lvm_thin_pool 'pool0' do
  group 'vg_data'
  size  '50G'

  thin_volume 'tv_app' do
    size '20G'
    filesystem 'xfs'
    mount_point '/srv/app'
  end

  thin_volume 'tv_db' do
    size '10G'
    filesystem 'ext4'
    mount_point '/var/lib/mysql'
  end
end
```
