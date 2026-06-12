# lvm_physical_volume

Manages LVM physical volumes (PVs) on block devices.

## Actions

| Action | Description |
|---|---|
| `:create` | Creates the physical volume if it does not already exist |
| `:resize` | Resizes the physical volume to fill its underlying block device |

## Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `volume_name` | `String` | name | Path to the block device (e.g. `/dev/sdb`) |
| `wipe_signatures` | `[true, false]` | `false` | Pass `--yes` to pvcreate to wipe existing signatures |
| `ignore_skipped_cluster` | `[true, false]` | `false` | Pass `--ignoreskippedcluster` to LVM commands |

## Examples

```ruby
lvm_physical_volume '/dev/sdb'

lvm_physical_volume '/dev/sdc' do
  wipe_signatures true
end

lvm_physical_volume '/dev/sdd' do
  action :resize
end
```
