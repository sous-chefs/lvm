# lvm Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/lvm.svg)](https://supermarket.chef.io/cookbooks/lvm)
[![CI State](https://github.com/sous-chefs/lvm/workflows/ci/badge.svg)](https://github.com/sous-chefs/lvm/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you'd like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

A gem-free rewrite of the [sous-chefs/lvm](https://github.com/sous-chefs/lvm) cookbook.

## What changed

The original cookbook required two compile-time gems (`chef-ruby-lvm` and
`chef-ruby-lvm-attrib`) that parsed LVM text output via large YAML attribute
tables. This rewrite removes both gems entirely and replaces them with direct
use of `lvm <cmd> --reportformat json`, which has been available in LVM since
version 2.02.158 (June 2016) — present on every supported distro.

| Original | This rewrite |
|---|---|
| `chef_gem 'chef-ruby-lvm'` at compile time | No gems, no compile-time installs |
| `chef_gem 'chef-ruby-lvm-attrib'` at compile time | No gems |
| YAML attribute tables per LVM version | `JSON.parse` on `lvs/vgs/pvs --reportformat json` |
| `LVM::LVM.new` Ruby objects | Plain Ruby `Hash` rows from the JSON report |
| `depends 'chef-sugar'` | No cookbook dependencies |

### Supported distros

Requires LVM ≥ 2.02.158 (ships with all non-EOL distros):

| Distro | LVM version |
|---|---|
| RHEL / CentOS / Rocky / AlmaLinux 7 | 2.02.187 |
| RHEL / CentOS / Rocky / AlmaLinux 8 | 2.03.18 |
| RHEL / CentOS / Rocky / AlmaLinux 9 | 2.03.23 |
| Ubuntu 18.04 LTS | 2.02.176 |
| Ubuntu 20.04 LTS | 2.03.07 |
| Ubuntu 22.04 LTS | 2.03.11 |
| Ubuntu 24.04 LTS | 2.03.16 |
| SLES 15 SP5 | 2.03.20 |
| SLES 15 SP6 | 2.03.23 |

---

## Resources

For full resource documentation see the [documentation](documentation/) folder.

| Resource | Description |
| -------- | ----------- |
| [lvm_physical_volume](documentation/lvm_physical_volume.md) | Create or remove an LVM physical volume |
| [lvm_volume_group](documentation/lvm_volume_group.md) | Create or extend an LVM volume group |
| [lvm_logical_volume](documentation/lvm_logical_volume.md) | Create, resize, or manage an LVM logical volume |
| [lvm_thin_pool](documentation/lvm_thin_pool.md) | Create an LVM thin pool |
| [lvm_thin_pool_meta](documentation/lvm_thin_pool_meta.md) | Manage the metadata volume of an existing thin pool |
| [lvm_thin_volume](documentation/lvm_thin_volume.md) | Create or resize a thin logical volume from a thin pool |

### Partials

| Partial | Consumers | Description |
| ------- | --------- | ----------- |
| [partial_lv_common](documentation/partial_lv_common.md) | all volume resources | Shared `group`, `size`, `physical_volumes`, `wipe_signatures`, `ignore_skipped_cluster` properties |
| [partial_lv_filesystem](documentation/partial_lv_filesystem.md) | `lvm_logical_volume`, `lvm_thin_volume` | `filesystem`, `mount_point`, LUKS encryption properties |
## Contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache-2.0 — see [LICENSE](LICENSE)
