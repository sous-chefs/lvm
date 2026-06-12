# Migration Guide — v6.x to v7.0.0

## Breaking Changes

### Gem dependencies removed

v7.0.0 removes the `chef-ruby-lvm` and `chef-ruby-lvm-attrib` gem dependencies.
LVM is now queried directly via `lvm --reportformat json`, which is available on
all supported platforms (LVM 2.02.158+).

**Impact**: No code changes required for cookbook consumers. The public resource API
is unchanged. The gems are no longer installed at Chef compile time.

### `recipes/default.rb` removed

The v6.x `default` recipe installed `lvm2`, `thin-provisioning-tools`, and managed
the `lvm2-lvmetad` service on RHEL 7. This recipe has been removed in v7.0.0.

**Migration**: Manage the `lvm2` package and optional services in your own wrapper cookbook:

```ruby
# In your wrapper cookbook or base role
package 'lvm2'
package 'thin-provisioning-tools' if platform_family?('debian')

# RHEL 7 only — lvmetad was removed in RHEL 8
if platform_family?('rhel') && node['platform_version'].to_i == 7 && !platform?('amazon')
  service 'lvm2-lvmetad' do
    action [:enable, :start]
    only_if '/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1'
  end
end
```

### Resources moved from `libraries/` to `resources/`

All resources are now flat `resources/*.rb` files using `unified_mode true`,
`property` declarations, and `converge_by` blocks. This is a Chef internal
implementation change with no impact on cookbook consumers.

### Minimum supported platforms updated

| Dropped | Reason |
|---|---|
| RHEL 6 / CentOS 6 | Ships LVM 2.02.84 — no `--reportformat json` support |
| Ubuntu 16.04 | EOL; ships LVM 2.02.133 — no JSON support |

## No API Changes

All existing resource names, properties, and DSL block helpers work identically in v7.0.0:

```ruby
# This v6.x code works unchanged in v7.0.0
lvm_volume_group 'vg0' do
  physical_volumes '/dev/sdb'
  logical_volume 'lv0' do
    size       '10G'
    filesystem 'ext4'
    mount_point '/data'
  end
end
```
