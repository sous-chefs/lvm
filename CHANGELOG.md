lvm Cookbook CHANGELOG
======================
This file is used to list changes made in each version of the lvm cookbook.

v1.3.7 (2015-06-20)
-------------------
- Allow users to specify the exact versions of the lvm gems (#49)
- Start/enable the lvmetad service on RHEL7. (#52)
- Allow arbitrary parameters to be passed to lvcreate.

v1.3.6 (2015-02-18)
-------------------
- Reverting chef_gem compile_time work

v1.3.5 (2015-02-18)
-------------------
- Fixing chef_gem with Chef::Resource::ChefGem.method_defined?(:compile_time)

v1.3.4 (2015-02-18)
-------------------
- Fixing chef_gem for Chef below 12.1.0

v1.3.3 (2015-02-17)
-------------------
- Being explicit about usage of the chef_gem's compile_time property.
- Eliminating future deprecation warning in Chef 12.1.0

v1.3.1 (2015-02-09)
-------------------
- #46 - Unbreak cookbook on Chef Client 12
- #34 - Add ability to specify optional filesystem parameters when formatting

v1.3.0 (2014-07-09)
-------------------
- #32 - add support for resizing logical and physical volumes
- #33 - [COOK-4701]: add ability to extend volume groups

v1.2.2 (2014-07-02)
-------------------
No changes. Bumping for toolchain

v1.2.0 (2014-07-02)
-------------------
- [COOK-2992] add support for resizing logical and physical volumes

v1.1.2 (2014-05-15)
-------------------
- [COOK-4609] Enable the logical volume if it is disabled

v1.1.0 (2014-04-10)
-------------------
- [COOK-4539] - Change default mount mode to 0755

v1.0.8 (2014-03-27)
-------------------
No change. Bumping version for toolchain

v1.0.6 (2014-03-27)
-------------------
- [COOK-4486] - Add ChefSpec matchers for LVM resources
- [COOK-4481] - The lvm_volume_group resource is not convergent

v1.0.4 (2013-12-28)
-------------------
### Bug
- **[COOK-3987](https://tickets.chef.io/browse/COOK-3987)** - Volumes are created with the wrong # of extents.  Size = '2%VG' is treated as a size of 2 extents.

v1.0.2
------
### Bug
- **[COOK-3935](https://tickets.chef.io/browse/COOK-3935)** - fix minor typo
- Fixing up style
- Updating test harness

v1.0.0
------
### Improvement
- **[COOK-3357](https://tickets.chef.io/browse/COOK-3357)** - Complete refactor into a heavy-weight provider with tests

v0.8.12
-------
### Improvement
- **[COOK-2991](https://tickets.chef.io/browse/COOK-2991)** - Add SLES support

### Bug
- **[COOK-2348](https://tickets.chef.io/browse/COOK-2348)** - Fix `lvm_logical_volume` when `mount_point` parameter is a String

v0.8.10
-------
### Bug
- [COOK-3031]: `ruby_block` to create logical volume is improperly named, causing collisions

v0.8.8
------
- [COOK-2283] - lvm version mismatch on fresh amazon linux install
- [COOK-2733] - Fix invalid only_if command in lvm cookbook
- [COOK-2822] - install, don't upgrade, lvm2 package

v0.8.6
------
- [COOK-2348] - lvm `logical_volume` doesn't work with `mount_point` parameter as String

v0.8.4
------
- [COOK-1977] - Typo "stripesize" in LVM cookbook
- [COOK-1994] - Cannot create a logical volume if fstype is not given

v0.8.2
------
- [COOK-1857] - `lvm_logical_volume` resource callback conflicts with code in provider.

v0.8.0
------
- Added providers for managing the creation of LVM physical volumes, volume groups, and logical volumes.

v0.7.1
------
- Current public release
