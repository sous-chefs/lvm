# lvm_volume_group

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Creates or extends an LVM volume group. Uses `vgcreate`/`vgextend` directly with `lvm vgs --reportformat json` for idempotency — no gem dependencies.

Introduced: v8.0.0

## Actions

| Action | Description |
| ------ | ----------- |
| `:create` | Create the VG if absent; extend with any new PVs if it exists (default) |
| `:extend` | Add PVs to an already-existing VG (idempotent) |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | String | _name property_ | Name of the volume group |
| `physical_volumes` | String, Array | _required_ | One or more block devices to include in this VG |
| `physical_extent_size` | String, Integer | `nil` | Physical extent size (e.g. `"32m"` or `32`). Passed to `vgcreate -s` |
| `logical_volumes` | Array | `[]` | Array of `lvm_logical_volume` resource objects to create inside this VG |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped during device scanning |

## Examples

```ruby
lvm_volume_group 'datavg' do
  physical_volumes '/dev/sdb'
end
```

```ruby
lvm_volume_group 'datavg' do
  physical_volumes ['/dev/sdb', '/dev/sdc']
  physical_extent_size '32m'
end
```

Extend an existing VG with a new PV:

```ruby
lvm_volume_group 'datavg' do
  physical_volumes '/dev/sdd'
  action :extend
end
```

Nested logical volumes:

```ruby
lvm_volume_group 'datavg' do
  physical_volumes '/dev/sdb'
  logical_volumes [
    lvm_logical_volume('datalv') { size '10G'; filesystem 'xfs'; mount_point '/data' },
  ]
end
```
