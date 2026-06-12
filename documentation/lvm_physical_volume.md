# lvm_physical_volume

[Back to Resource List](https://github.com/sous-chefs/lvm#resources)

Creates or removes an LVM physical volume on a block device. Uses `pvcreate`/`pvremove` directly with `lvm pvs --reportformat json` for idempotency — no gem dependencies.

Introduced: v8.0.0

## Actions

| Action | Description |
| ------ | ----------- |
| `:create` | Create the physical volume if it does not exist (default) |
| `:remove` | Remove the physical volume |

## Properties

| Name | Type | Default | Description |
| ---- | ---- | ------- | ----------- |
| `name` | String | _name property_ | Block device path (e.g. `/dev/sdb`) |
| `ignore_skipped_cluster` | true, false | `false` | Suppress errors when a clustered VG is skipped during device scanning |

## Examples

```ruby
lvm_physical_volume '/dev/sdb'
```

```ruby
lvm_physical_volume '/dev/sdc' do
  action :create
end
```

```ruby
lvm_physical_volume '/dev/sdb' do
  action :remove
end
```
