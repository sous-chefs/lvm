# lvm_thin_pool_meta_data

Resizes the metadata volume of an LVM thin pool.

## Actions

| Action | Description |
|---|---|
| `:resize` | Extends the thin pool metadata volume to the requested size |

## Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `name` | `String` | name | Name of the metadata volume (e.g. `pool0_tmeta`) |
| `group` | `String` | — | **Required.** Volume group name |
| `pool` | `String` | — | **Required.** Parent thin pool LV name |
| `size` | `String` | — | **Required.** New metadata size (e.g. `512M`, `1G`) |

## Examples

```ruby
lvm_thin_pool_meta_data 'pool0_tmeta' do
  group 'vg_data'
  pool  'pool0'
  size  '512M'
end
```
