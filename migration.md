# Migration Guide

This release migrates the lvm cookbook from legacy recipes, node attributes, and HWRP library classes to modern custom resources.

## Breaking Changes

* The `lvm::default` recipe has been removed.
* The `attributes/default.rb` file has been removed.
* The `chef-ruby-lvm` and `chef-ruby-lvm-attrib` gem dependency configuration has been removed.
* Legacy library-based resource and provider classes have been replaced by resources in `resources/`.

## Attribute Migration

The old cookbook installed and pinned LVM helper gems through node attributes. Those attributes are no longer used because the cookbook now queries LVM state directly with LVM2 JSON output.

Remove attribute overrides like this from roles, environments, wrappers, and Policyfiles:

```ruby
default['lvm']['di-ruby-lvm']['version'] = '0.4.3'
default['lvm']['di-ruby-lvm-attrib']['version'] = '0.7.2'
```

## Recipe Migration

Replace `include_recipe 'lvm'` with package installation and direct resource declarations in your wrapper cookbook.

Before:

```ruby
include_recipe 'lvm'

lvm_volume_group 'data' do
  physical_volumes ['/dev/sdb']
end
```

After:

```ruby
package 'lvm2'

lvm_volume_group 'data' do
  physical_volumes ['/dev/sdb']
end
```

On Debian-family platforms that use thin provisioning, install the thin provisioning tools package before declaring thin resources:

```ruby
package 'thin-provisioning-tools'

lvm_thin_pool 'pool0' do
  group 'data'
  size '50G'
end
```

## Resource Names

Use the modern custom resources directly:

* `lvm_physical_volume`
* `lvm_volume_group`
* `lvm_logical_volume`
* `lvm_thin_pool`
* `lvm_thin_pool_meta_data`
* `lvm_thin_volume`

See the individual files in `documentation/` for resource properties and examples.
