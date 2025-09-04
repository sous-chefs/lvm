# lvm Cookbook CHANGELOG

This file is used to list changes made in each version of the lvm cookbook.

## 6.2.3 - *2025-09-04*

Standardise files with files in sous-chefs/repo-management

## 6.2.2 - *2025-02-21*

- Bump gem to 0.4.2
- CI: Update tested platforms
- CI: Switch to using ubuntu-latest and manually install VirtualBox

## 6.2.1 - *2024-11-18*

- Standardise files with files in sous-chefs/repo-management

## 6.2.0 - *2024-09-05*

- Update chef-ruby-lvm-attrib gem to 0.4.0

## 6.1.23 - *2024-07-15*

- Standardise files with files in sous-chefs/repo-management

## 6.1.22 - *2024-05-03*

## 6.1.21 - *2024-05-02*

## 6.1.20 - *2024-04-30*

## 6.1.19 - *2024-04-30*

## 6.1.18 - *2024-04-30*

- Update chef-ruby-lvm-attrib gem to 0.3.15

## 6.1.17 - *2023-11-01*

- Update chef-ruby-lvm-attrib gem to 0.3.14

## 6.1.16 - *2023-10-03*

## 6.1.15 - *2023-09-29*

## 6.1.14 - *2023-05-17*

## 6.1.13 - *2023-04-04*

- Standardise files with files in sous-chefs/repo-management

## 6.1.12 - *2023-04-01*

- Standardise files with files in sous-chefs/repo-management

## 6.1.11 - *2023-04-01*

- Standardise files with files in sous-chefs/repo-management

## 6.1.10 - *2023-04-01*

- Standardise files with files in sous-chefs/repo-management

## 6.1.9 - *2023-03-20*

- Standardise files with files in sous-chefs/repo-management

## 6.1.8 - *2023-03-15*

- Standardise files with files in sous-chefs/repo-management

## 6.1.7 - *2023-03-02*

## 6.1.6 - *2023-02-27*

## 6.1.5 - *2023-02-27*

- Standardise files with files in sous-chefs/repo-management

## 6.1.4 - *2023-02-15*

- Standardise files with files in sous-chefs/repo-management

## 6.1.3 - *2022-12-13*

- Standardise files with files in sous-chefs/repo-management

## 6.1.2 - *2022-09-30*

- Update chef-ruby-lvm-attrib gem to 0.3.11

## 6.1.1 - *2022-09-29*

- Fix parsing of output from `blkid` in `libraries/provider_lvm_logical_volume.rb` due to different behavior under busybox (e.g., running in hab effortless)

## 6.1.0 - *2022-08-07*

- Fix `pvcreate` and `lvcreate` to return an error if a valid signature was found on the device instead of waiting interactivly for confirmation.

## 6.0.2 - *2022-08-07*

- CI: Remove use of Vagrant boxes from OSUOSL
- CI: Fix loop file creation on Ubuntu 20.04

## 6.0.1 - *2022-07-29*

- Update chef-ruby-lvm-attrib gem to 0.3.10

## 6.0.0 - *2022-04-25*

Standardise files with files in sous-chefs/repo-management

- Standardise files with files in sous-chefs/repo-management
- Remove Gemfile and the community cookbook releaser
- Always turn on unfied_mode so we get consistent behaviour
- Require Chef 15.3 for unified_mode
- Turn on unified_mode

## 5.2.2 - *2022-02-08*

- Remove delivery folder

## 5.2.1 - *2021-11-23*

- Add CentOS Stream 8 to CI pipeline
- Update chef-ruby-lvm-attrib gem to 0.3.9

## 5.2.0 - *2021-10-22*

- Use default Chef source for gems

## 5.1.0 - *2021-10-14*

- Sous Chefs adoption
- Standardise files with files in sous-chefs/repo-management
- Enable `unified_mode` if supported
- resolved cookstyle error: test/fixtures/cookbooks/test/resources/loop_devices.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- Move resource documentation into individual files out of README
- Migrate to InSpec tests
- Install thin-provisioning-tools on Debian-based systems
- Add GitHub CI

## 5.0.7 (2021-07-22)

- Update the attributes gem version from 0.3.6 to 0.3.7 [@wheatevo](https://github.com/wheatevo)

## 5.0.6 (2021-02-09)

- Need to add explicit parameters for super called from action methods - [@b-dean](https://github.com/b-dean)

## 5.0.5 (2020-11-13)

- Update the attributes gem version from 0.3.5 to 0.3.6 [@gaelik](https://github.com/gaelik)

## 5.0.4 (2020-10-02)

- Standardise files with files in chef-cookbooks/repo-management - [@xorimabot](https://github.com/xorimabot)
- Chase upstream chef-ruby-lvm-attrib version - [@jflemer-ndp](https://github.com/jflemer-ndp)

## 5.0.3 (2020-08-25)

- Support Chef Infra Client 16 and ubuntu 20.04 - [@duncaan](https://github.com/duncaan)
- resolved cookstyle error: libraries/provider_lvm_logical_volume.rb:45:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_logical_volume.rb:129:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_logical_volume.rb:221:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_thin_pool.rb:36:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_thin_pool.rb:41:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_thin_pool_meta_data.rb:41:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_volume_group.rb:43:7 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_lvm_volume_group.rb:66:7 refactor: `ChefModernize/ActionMethodInResource`

## 5.0.2 (2020-06-02)

- Cookstyle fixes including Chef Infra Client 16 fixes - [@xorimabot](https://github.com/xorimabot)
  - resolved cookstyle error: libraries/provider_lvm_logical_volume.rb:21:1 refactor: `ChefModernize/IncludingMixinShelloutInResources`
  - resolved cookstyle error: libraries/provider_lvm_logical_volume.rb:32:7 refactor: `ChefModernize/IncludingMixinShelloutInResources`
  - resolved cookstyle error: libraries/provider_lvm_thin_pool_meta_data.rb:21:1 refactor: `ChefModernize/IncludingMixinShelloutInResources`
  - resolved cookstyle error: libraries/provider_lvm_thin_pool_meta_data.rb:31:7 refactor: `ChefModernize/IncludingMixinShelloutInResources`
  - resolved cookstyle error: libraries/provider_lvm_volume_group.rb:21:1 refactor: `ChefModernize/IncludingMixinShelloutInResources`
  - resolved cookstyle error: libraries/provider_lvm_volume_group.rb:31:7 refactor: `ChefModernize/IncludingMixinShelloutInResources`
  - resolved cookstyle error: libraries/resource_lvm_logical_volume.rb:28:7 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: libraries/resource_lvm_thin_pool.rb:29:7 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: libraries/resource_lvm_thin_pool_meta_data.rb:29:7 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: libraries/resource_lvm_thin_volume.rb:29:7 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: libraries/resource_lvm_volume_group.rb:29:7 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: test/fixtures/cookbooks/test/resources/loop_devices.rb:1:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`

## 5.0.1 (2020-05-27)

- Update the attributes gem version from 0.3.1 to 0.3.2

## 5.0.0 (2020-05-01)

The 5.0 release of this cookbook no longer cleans up the legacy di-ruby-lvm-attrib and di-ruby-lvm gems. These gems were replaced and the cleanup was added ~3 years ago. Any upgrade to this cookbook or to the Chef Infra Client would remove the legacy gems. If you are trying to upgrade from a VERY old version of this cookbook to current you'll either need to perform that cleanup by hand in a wrapper cookbook or you'll want to use the 4.x release first to perform the cleanup.

## 4.6.1 (2020-04-15)

- Require the chef-ruby-lvm-attrib 0.3.1 gem - [@tas50](https://github.com/tas50)

## 4.6.0 (2020-01-04)

- Remove extra metadata from the metadata.rb - [@tas50](https://github.com/tas50)
- Remove the foodcritic config - [@tas50](https://github.com/tas50)
- Update copyrights - [@tas50](https://github.com/tas50)
- Use ::File not File in the conditionals - [@tas50](https://github.com/tas50)
- Simplify types in the resources - [@tas50](https://github.com/tas50)
- Switch testing to Github actions - [@tas50](https://github.com/tas50)
- Require Chef 12.15+ - [@tas50](https://github.com/tas50)
- Fix the failing specs - [@tas50](https://github.com/tas50)

## 4.5.4 (2019-08-20)

- Update the attributes gem version from 0.2.6 to 0.2.8

## 4.5.3 (2018-12-26)

- Add support for the ignore_skipped_cluster property, fixes #170 - [msgarbossa](https://github.com/msgarbossa)

## 4.5.2 (2018-11-01)

- Update the attributes gem version from 0.2.5 to 0.2.6

## 4.5.1 (2018-11-01)

- Update the attributes gem version from 0.2.3 to 0.2.5

## 4.5.0 (2018-09-11)

- Added the ability to remove a logical volume, fixes #124
- Added documentation on :remove action for lvm_logical_volume resource within the readme
- Documented integration tests unable to function unless minimal Chef 13.x due to ruby 2.4.x dependency (development impact only, not operational impact)

## 4.4.0 (2018-08-10)

- Added 'lv_params' to be handled as part of lvm_logical_volume :resize, as it was available only for :create - to resolve GH-159
- Added logic to not pass '--resizefs' if the filesystem is 'RAW'
- Added missing documentation on the hidden option of sending 'lv_params' to the resource for both :create and :resize

## 4.3.0 (2018-07-31)

- Added new lvm_thin_pool_meta_data resource

## 4.2.0 (2018-07-24)

- Convert physical_volume to a custom resource
- Add support for the ignore_skipped_cluster property, fixes #156

## 4.1.15 (2018-06-29)

- Fix resources so ChefSpec matchers are auto-generated
- Fix wording in the readme
- Add specs

## 4.1.14 (2018-06-11)

- Remove the ChefSpec matchers which are autogenerated by ChefSpec now
- Resolve Chef 12 resource cloning deprecation warning

## 4.1.13 (2018-05-01)

- Update chef-ruby-lvm-attrib to 0.2.3

## 4.1.12 (2018-03-19)

- Fix passing nils to Chef 14

## 4.1.11 (2018-03-09)

- Correct raise syntax to remove the invalid second argument, fixes #141

## 4.1.10 (2017-11-26)

- updating to version 0.2.2 of chef-ruby-lvm-attrib

## 4.1.9 (2017-10-04)

- Remove end.run_action resource declaration from e2fsprogs package installation on SUSE platform.

## 4.1.8 (2017-09-28)

- Raise on errors instead of calling Application fatal so we can ignore failures on the LVM resources

## 4.1.7 (2017-09-15)

- Require latest lvm-attrib gem

## 4.1.6 (2017-08-15)

- Fix for size in extents --extents should be used

## 4.1.5 (2017-08-15)

- Add missing matchers for lvm thin pools and volumes

## 4.1.4 (2017-06-21)

- Require the latest lvm gem which allows for the latest attrib gem

## 4.1.3 (2017-06-21)

- Require the latest chef-ruby-lvm-attrib gem to support recent distros like RHEL 7.2/7.3

## 4.1.2 (2017-06-20)

- Ensure metadata parsing doesn't fail on older chef 12 releases

## 4.1.1 (2017-06-20)

- Adding source for the air gaped environment use case.
- Don't start lvm2-lvmetad on amazon linux when on Chef < 13

## 4.1.0 (2017-04-26)

- Fix invalid platform sles in metadata
- Allowing a different source for gem install

## 4.0.6 (2017-03-29)

- Only cleanup gems once in a chef run

## 4.0.5 (2017-01-09)

- fix false coerce float error

## 4.0.4 (2016-12-20)

- Remove deprecation notices introduced in 4.0.1

## 4.0.3 (2016-12-19)

- Include platformintrospection dsl to fix suse check failures

## 4.0.2 (2016-12-15)

- Warn if the attributes are set vs. a hard failure
- Document the new gem changes in the readme

## 4.0.1 (2016-12-14)

- Uninstall the previous lvm gems to prevent failures installing the new chef forks

## 4.0.0 (2016-12-12)

### Breaking changes

- This cookbook has switched from the di-ruby-lvm/di-ruby-lvm-attrib gems to chef-ruby-lvm/chef-ruby-lvm-attrib forks. This was done to ensure that the latest lvm releases are always supported by the cookbooks and brings with it support for RHEL 7.3. If you have previously pinned gem versions you will need to update to the new attributes.

## Other changes

- Added "yes_flag" also to PV and LV create"
- Format and reword the readme
- Remove need for apt for testing
- Fix Suse support if using ext filesystems by installing the e2fsprogs package if necessary

## 3.1.0 (2016-10-26)

- Remove chef 11 compatibility from chef_gem install
- Update to di-ruby-lvm-attrib 0.0.27

## 3.0.0 (2016-09-16)

- Testing updates
- update to add chefspec runner methods
- Require Chef 12.1+

## v2.1.2 (2016-06-14)

- Prevent failures in other cookbooks utilizing the lvm resources

## v2.1.1 (2016-06-10)

- Update di-ruby-lvm-attrib to 0.0.26

## v2.1.0 (2016-05-11)

- Added lvm_thin_pool and lvm_thin_volume resources

## v2.0.0 (2016-04-11)

- The gems are now installed when the provider is first used instead of in the default recipe. For users that already have the LVM package installed there is no need to include the default recipe on their run_list now
- Due to how the gem is installed now this recipe now requires Chef 12.0+
- Added RHEL 7.0 specs for the default recipe

## v1.6.1 (2016-03-23)

- Fixed compile time installs of di-ruby-lvm

## v1.6.0 (2016-03-23)

- Add a wipe_signatures option to LVM volume group

## v1.5.2 (2016-03-23)

- Update di-ruby-lvm-attrib to 0.0.25

## v1.5.1 (2016-01-26)

- Added attributes to allow installing the lvm gems at compile time
- Removed yum cookbook from the Berksfile as it wasn't being used
- Improved testing with chefspec and test kitchen

## v1.5.0 (2015-12-09)

- Update the di-ruby-lvm and di-ruby-lvm-attrib gems to the latest release to improve speed and the supported versions of LVM
- Add testing of the resizing to Travis CI and the Kitchen config
- Resolve issues when running under Chefspec

## v1.4.1 (2015-11-17)

- Change chef_gem installs to not install at compile_time on Chef 12 to avoid warnings

## v1.4.0 (2015-10-22)

- Updated the minimum supported Chef release from 10 -> 11 in the readme
- Updated di-ruby-lvm-attrib gem from 0.0.16 -> 0.0.21
- Added Chef 11 compatibility to the source_url and issues_url in the metadata
- Added support for additional RHEL deritivites to the metadata
- Added additional Chefspec matchers
- Added chefignore file to limit what files are uploaded to the Chef server
- Added Test Kitchen config
- Updated .gitignore
- Updated to use Chef standard rubocop config
- Updated Travis config to test using ChefDK vs. Gems
- Updated contributing and testing docs
- Added maintainers.md and maintainers.toml files
- Updated development dependencies in the Gemfile
- Added cookbook version badge to the readme

## v1.3.7 (2015-06-20)

- Allow users to specify the exact versions of the lvm gems (#49)
- Start/enable the lvmetad service on RHEL7\. (#52)
- Allow arbitrary parameters to be passed to lvcreate.

## v1.3.6 (2015-02-18)

- Reverting chef_gem compile_time work

## v1.3.5 (2015-02-18)

- Fixing chef_gem with Chef::Resource::ChefGem.method_defined?(:compile_time)

## v1.3.4 (2015-02-18)

- Fixing chef_gem for Chef below 12.1.0

## v1.3.3 (2015-02-17)

- Being explicit about usage of the chef_gem's compile_time property.
- Eliminating future deprecation warning in Chef 12.1.0

## v1.3.1 (2015-02-09)

- 46 - Unbreak cookbook on Chef Client 12
- 34 - Add ability to specify optional filesystem parameters when formatting

## v1.3.0 (2014-07-09)

- 32 - add support for resizing logical and physical volumes
- 33 - [COOK-4701]: add ability to extend volume groups

## v1.2.2 (2014-07-02)

No changes. Bumping for toolchain

## v1.2.0 (2014-07-02)

- [COOK-2992] add support for resizing logical and physical volumes

## v1.1.2 (2014-05-15)

- [COOK-4609] Enable the logical volume if it is disabled

## v1.1.0 (2014-04-10)

- [COOK-4539] - Change default mount mode to 0755

## v1.0.8 (2014-03-27)

No change. Bumping version for toolchain

## v1.0.6 (2014-03-27)

- [COOK-4486] - Add ChefSpec matchers for LVM resources
- [COOK-4481] - The lvm_volume_group resource is not convergent

## v1.0.4 (2013-12-28)

- **COOK-3987** - Volumes are created with the wrong # of extents. Size = '2%VG' is treated as a size of 2 extents.

## v1.0.2

- **COOK-3935** - fix minor typo
- Fixing up style
- Updating test harness

## v1.0.0

- **COOK-3357** - Complete refactor into a heavy-weight provider with tests

## v0.8.12

- **COOK-2991** - Add SLES support
- **COOK-2348** - Fix `lvm_logical_volume` when `mount_point` parameter is a String

## v0.8.10

- [COOK-3031]: `ruby_block` to create logical volume is improperly named, causing collisions

## v0.8.8

- [COOK-2283] - lvm version mismatch on fresh amazon linux install
- [COOK-2733] - Fix invalid only_if command in lvm cookbook
- [COOK-2822] - install, don't upgrade, lvm2 package

## v0.8.6

- [COOK-2348] - lvm `logical_volume` doesn't work with `mount_point` parameter as String

## v0.8.4

- [COOK-1977] - Typo "stripesize" in LVM cookbook
- [COOK-1994] - Cannot create a logical volume if fstype is not given

## v0.8.2

- [COOK-1857] - `lvm_logical_volume` resource callback conflicts with code in provider.

## v0.8.0

- Added providers for managing the creation of LVM physical volumes, volume groups, and logical volumes.

## v0.7.1

- Current public release
