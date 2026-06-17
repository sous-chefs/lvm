# Migration Guide

This release migrates the lvm cookbook from legacy recipes, node attributes, HWRP library classes,
and external gem dependencies to modern custom resources with zero external dependencies.

## Breaking Changes

* The `lvm::default` recipe has been removed.
* The `attributes/default.rb` file has been removed.
* The `chef-ruby-lvm` and `chef-ruby-lvm-attrib` gem dependencies have been removed entirely.
* Legacy library-based resource and provider classes have been replaced by custom resources
  in `resources/`.
* All cookbook dependencies have been removed — this cookbook is fully standalone.
* Minimum Chef version requirement is now **Chef 16.0+**.

## Attribute Migration

The old cookbook installed and pinned LVM helper gems through node attributes. Those attributes
are no longer used because the cookbook now queries LVM state directly using LVM2's built-in
`--reportformat json` output.

Remove attribute overrides like these from roles, environments, wrappers, and Policyfiles:

```ruby
default['lvm']['di-ruby-lvm']['version'] = '0.4.3'
default['lvm']['di-ruby-lvm-attrib']['version'] = '0.7.2'
```

No replacement attributes are needed — the cookbook is now configuration-free.

## Recipe Migration

Replace `include_recipe 'lvm'` with the `lvm2` package and direct resource declarations in
your wrapper cookbook:

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

On Debian-family platforms that use thin provisioning, also install the thin provisioning tools
package before declaring thin resources:

```ruby
package %w(lvm2 thin-provisioning-tools)

lvm_thin_pool 'pool0' do
  group 'data'
  size '50G'
end
```

## Dependency Migration

If your `metadata.rb` or `Policyfile.rb` declared a dependency on this cookbook solely for the
recipe, you can simplify:

Before (`metadata.rb`):

```ruby
depends 'lvm'
```

After — keep the dependency only if you use the custom resources. The cookbook no longer pulls in
any transitive cookbook or gem dependencies.

## Resource Names

The custom resources are unchanged and fully backward-compatible:

* `lvm_physical_volume`
* `lvm_volume_group`
* `lvm_logical_volume`
* `lvm_thin_pool`
* `lvm_thin_pool_meta_data`
* `lvm_thin_volume`

All existing resource properties remain the same — no property renames or removals.

See the individual files in `documentation/` for full resource properties and usage examples.
