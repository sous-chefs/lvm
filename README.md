# lvm Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/lvm.svg)](https://supermarket.chef.io/cookbooks/lvm)
[![CI State](https://github.com/sous-chefs/lvm/workflows/ci/badge.svg)](https://github.com/sous-chefs/lvm/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Resource-driven cookbook for managing LVM physical volumes, volume groups, and logical volumes using LVM2 built-in JSON reporting.

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you'd like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Requirements

### Platforms

- AlmaLinux 8+
- Amazon Linux 2023+
- CentOS Stream 9+
- Debian 12+
- Fedora (latest)
- openSUSE Leap 15+
- Oracle Linux 8+
- Rocky Linux 8+
- Ubuntu 22.04+

### Chef

- Chef >= 16.0

### LVM2

- LVM2 >= 2.02.158 (released 2017; required for `--reportformat json` support)

### Cookbooks

- none

## Usage

Declare a dependency on `lvm` in your cookbook metadata:

```ruby
# your_cookbook/metadata.rb
depends 'lvm'
```

Then use the resources directly in your recipes:

```ruby
# Create a physical volume
lvm_physical_volume '/dev/sdb'

# Create a volume group from physical volumes
lvm_volume_group 'data' do
  physical_volumes ['/dev/sdb']
end

# Create a logical volume
lvm_logical_volume 'logs' do
  group      'data'
  size       '10G'
  filesystem 'ext4'
  mount_point '/var/log/app'
end

# Create a thin pool inside a volume group
lvm_thin_pool 'pool0' do
  group 'data'
  size  '50G'
end

# Create a thin volume from a thin pool
lvm_thin_volume 'app' do
  group     'data'
  pool      'pool0'
  size      '20G'
  filesystem 'xfs'
  mount_point '/srv/app'
end
```

## Resources

- [lvm_logical_volume](documentation/lvm_logical_volume.md)
- [lvm_physical_volume](documentation/lvm_physical_volume.md)
- [lvm_thin_pool](documentation/lvm_thin_pool.md)
- [lvm_thin_pool_meta_data](documentation/lvm_thin_pool_meta_data.md)
- [lvm_thin_volume](documentation/lvm_thin_volume.md)
- [lvm_volume_group](documentation/lvm_volume_group.md)

## Contributors

This project exists thanks to all the people who [contribute.](https://opencollective.com/sous-chefs/contributors.svg?width=890&button=false)

### Backers

Thank you to all our backers!

![https://opencollective.com/sous-chefs#backers](https://opencollective.com/sous-chefs/backers.svg?width=600&avatarHeight=40)

### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website.

![https://opencollective.com/sous-chefs/sponsor/0/website](https://opencollective.com/sous-chefs/sponsor/0/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/1/website](https://opencollective.com/sous-chefs/sponsor/1/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/2/website](https://opencollective.com/sous-chefs/sponsor/2/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/3/website](https://opencollective.com/sous-chefs/sponsor/3/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/4/website](https://opencollective.com/sous-chefs/sponsor/4/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/5/website](https://opencollective.com/sous-chefs/sponsor/5/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/6/website](https://opencollective.com/sous-chefs/sponsor/6/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/7/website](https://opencollective.com/sous-chefs/sponsor/7/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/8/website](https://opencollective.com/sous-chefs/sponsor/8/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/9/website](https://opencollective.com/sous-chefs/sponsor/9/avatar.svg?avatarHeight=100)
