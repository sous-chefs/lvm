# lvm Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/lvm.svg)](https://supermarket.chef.io/cookbooks/lvm)
[![CI State](https://github.com/sous-chefs/lvm/workflows/ci/badge.svg)](https://github.com/sous-chefs/lvm/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Installs lvm2 package and includes resources for managing LVM.

## Note on LVM gems

This cookbook has used multiple variants of the ruby-lvm and ruby-lvm-attrib gems for interacting with LVM. Most recently we used di-ruby-lvm and di-ruby-lvm-attrib gems, which are no longer being maintained. As of the 4.0 release this cookbook uses new Chef maintained gems: chef-ruby-lvm and chef-ruby-lvm-attrib. Previous versions of this cookbook supported cleaning those gems up for approximetly 3 years. At this point you'll need to remove those gems yourself if they're still present as the namespaces will conflict. If you previously used attributes to control the version of the gems to install, you will need to update to the latest attribute names to maintain that functionality.

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you’d like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Requirements

### Platforms

- Debian/Ubuntu
- RHEL/CentOS/Scientific/Amazon/Oracle
- SLES

### Chef

- Chef 12.15+

### Cookbooks

- none

## Resources

The following resources are provided:

- [lvm_logical_volume](documentation/lvm_logical_volume.md)
- [lvm_physical_volume](documentation/lvm_physical_volume.md)
- [lvm_thin_pool](documentation/lvm_thin_pool.md)
- [lvm_thin_pool_meta_data](documentation/lvm_thin_pool_meta_data.md)
- [lvm_thin_volume](documentation/lvm_thin_volume.md)
- [lvm_volume_group](documentation/lvm_volume_group.md)

## Usage

Include the default recipe in your run list on a node, in a role, or in another recipe:

```ruby
run_list(
  'recipe[lvm::default]'
)
```

Depend on `lvm` in any cookbook that uses its Resources/Providers:

```ruby
# other_cookbook/metadata.rb
depends 'lvm'
```

## Caveats

This cookbook depends on the [chef-ruby-lvm](https://github.com/chef/chef-ruby-lvm) and [chef-ruby-lvm-attrib](https://github.com/chef/chef-ruby-lvm-attrib) gems. The chef-ruby-lvm-attrib gem in particular is a common cause of failures when using the providers. If you get a failure with an error message similar to

```text
No such file or directory - /opt/chef/.../chef-ruby-lvm-attrib-0.0.3/lib/lvm/attributes/2.02.300(2)/lvs.yaml
```

then you are running a version of lvm that the gems do not support. However, getting support added is usually pretty easy. Just follow the instructions on "Adding Attributes" in the [chef-ruby-lvm-attrib README](https://github.com/chef/chef-ruby-lvm-attrib).

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
