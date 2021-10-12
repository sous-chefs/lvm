[Back to resource list](../README.md#resources)

# lvm_thin_pool_meta_data

Manages LVM thin pool metadata size.

## Actions

| Action    | Description                                                                                                                                                            |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:resize` | Resize an existing thin pool metadata volume (resizing only handles extending existing, this action will not shrink volumes due to the `lvextend` command being passed |

## Properties

| Name    | Type   | Default       | Description                                                                  |
| ------- | ------ | ------------- | ---------------------------------------------------------------------------- |
| `name`  | String | name property | Name of the thin pool metadata volume                                        |
| `group` | String |               | (required) Name of volume group in which thin pool metadata volume exist     |
| `pool`  | String |               | (required) Name of thin pool volume in which thin pool metadata volume exist |
| `size`  | String |               | (required) Size of the thin pool metadata volume                             |

### size

- It can be the size of the volume with units (k, K, m, M, g, G, t, T)

## Examples

```ruby
lvm_thin_pool_meta_data 'lv-thin-pool_tmeta' do
  group       'vg00'
  pool        'lv-thin-pool'
  size        '2M'
  action      :resize
end
```
