
# lvm_physical_volume

[Back to resource list](../README.md#resources)

Manages LVM physical volumes.

## Actions

| Action    | Description                             |
| --------- | --------------------------------------- |
| `:create` | (default) Creates a new physical volume |
| `:resize` | Resize an existing physical volume      |

## Properties

| Name               | Type           | Default       | Description                                                                            |
| ------------------ | -------------- | ------------- | -------------------------------------------------------------------------------------- |
| `volume_name`      | String         | name property | Device name of the physical volume (e.g. `/dev/sdb`)                                   |
| `wipe_signatures`  | `true`,`false` | `false`       | Whether to wipe existing signatures before creating the physical volume                |

## Examples

```ruby
lvm_physical_volume '/dev/sda'

lvm_physical_volume '/dev/sdb' do
  wipe_signatures true
end

lvm_physical_volume '/dev/sdc' do
  action :resize
end
```
