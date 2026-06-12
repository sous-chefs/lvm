# lvm Cookbook

[![CI](https://github.com/sous-chefs/lvm/actions/workflows/ci.yml/badge.svg)](https://github.com/sous-chefs/lvm/actions/workflows/ci.yml)

Provides custom resources for managing [Logical Volume Manager (LVM)](https://sourceware.org/lvm2/) on Linux.

## Supported Platforms

| Platform | Version |
|---|---|
| RHEL / CentOS / AlmaLinux / Rocky | >= 7.0 |
| Ubuntu | >= 18.04 |
| SUSE Linux Enterprise / openSUSE Leap | >= 15.0 |
| Amazon Linux | >= 2 |

> **LVM version requirement**: All supported platforms ship LVM 2.02.166 or newer, which provides `--reportformat json` support. See [LIMITATIONS.md](LIMITATIONS.md) for details.

## Requirements

- Chef Infra Client >= 15.3
- The `lvm2` package (managed manually or by your base OS recipe)
- `thin-provisioning-tools` on Debian/Ubuntu for thin pool support

## Resources

| Resource | Description |
|---|---|
| [`lvm_physical_volume`](documentation/lvm_physical_volume.md) | Manage PVs |
| [`lvm_volume_group`](documentation/lvm_volume_group.md) | Manage VGs with inline LVs |
| [`lvm_logical_volume`](documentation/lvm_logical_volume.md) | Manage standard LVs |
| [`lvm_thin_pool`](documentation/lvm_thin_pool.md) | Manage thin-provisioning pools |
| [`lvm_thin_volume`](documentation/lvm_thin_volume.md) | Manage thin logical volumes |
| [`lvm_thin_pool_meta_data`](documentation/lvm_thin_pool_meta_data.md) | Resize thin pool metadata |

## Usage

```ruby
# Install lvm2 first (not managed by this cookbook)
package 'lvm2'

# Create PVs
lvm_physical_volume '/dev/sdb'
lvm_physical_volume '/dev/sdc'

# Create a VG with LVs declared inline
lvm_volume_group 'vg_data' do
  physical_volumes ['/dev/sdb', '/dev/sdc']

  logical_volume 'lv_app' do
    size        '20G'
    filesystem  'xfs'
    mount_point '/srv/app'
  end

  logical_volume 'lv_logs' do
    size               '100%FREE'
    take_up_free_space true
    filesystem         'ext4'
    mount_point        '/var/log/app'
  end
end

# Or manage LVs independently
lvm_logical_volume 'lv_data' do
  group      'vg_data'
  size       '50G'
  filesystem 'ext4'
  mount_point(location: '/data', options: 'defaults,noatime', dump: 0, pass: 2)
end

# Thin provisioning
lvm_volume_group 'vg_thin' do
  physical_volumes '/dev/sdd'

  thin_pool 'pool0' do
    size '40G'

    thin_volume 'tv_app' do
      size '20G'
      filesystem 'xfs'
      mount_point '/srv/containers'
    end
  end
end
```

## Migration from v6.x

This cookbook was rewritten in v7.0.0 to remove the `chef-ruby-lvm` and
`chef-ruby-lvm-attrib` gem dependencies. See [migration.md](migration.md) for details.

## Maintainers

This cookbook is maintained by the [Sous Chefs](https://sous-chefs.org/) organisation.

## License

Copyright 2009-2024, Chef Software, Inc.

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
