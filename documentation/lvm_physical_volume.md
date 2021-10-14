[Back to resource list](../README.md#resources)

# lvm_physical_volume

Manages LVM physical volumes.

## Actions

| Action    | Description                             |
| --------- | --------------------------------------- |
| `:create` | (default) Creates a new physical volume |
| `:resize` | Resize an existing physical volume      |

## Properties

| Name                     | Type           | Default       | Description                                                                            |
| ------------------------ | -------------- | ------------- | -------------------------------------------------------------------------------------- |
| `volume_name`            | String         | name property | The device to create the new physical volume on                                        |
| `wipe_signatures`        | `true`,`false` | `false`       | Force the creation of the Logical Volume, even if `lvm` detects existing PV signatures |
| `ignore_skipped_cluster` | `true`,`false` | `false`       | Continue execution even if `lvm` detects skipped clustered volume groups               |

## Examples

```ruby
lvm_physical_volume '/dev/sda'

lvm_physical_volume '/dev/sdb' do
  action :resize
end
```
