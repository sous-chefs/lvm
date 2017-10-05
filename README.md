# lvm Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/lvm.svg?branch=master)](https://travis-ci.org/chef-cookbooks/lvm) [![Cookbook Version](https://img.shields.io/cookbook/v/lvm.svg)](https://supermarket.chef.io/cookbooks/lvm)

Installs lvm2 package and includes resources for managing LVM.

## Note on LVM gems

This cookbook has used multiple variants of the ruby-lvm and ruby-lvm-attrib gems for interacting with LVM. Most recently we used di-ruby-lvm and di-ruby-lvm-attrib gems, which are no longer being maintained. As of the 4.0 release this cookbook uses new Chef maintained gems: chef-ruby-lvm and chef-ruby-lvm-attrib. The cookbook will first remove the old gems before load/installing the new gems, in order to prevent gem conflicts. If you previously used attributes to control the version of the gems to install, you will need to update to the latest attribute names to maintain that functionality.

## Requirements

### Platforms

- Debian/Ubuntu
- RHEL/CentOS/Scientific/Amazon/Oracle
- SLES

### Chef

- Chef 12.1+

### Cookbooks

- none

## Resources/Providers

### lvm_physical_volume

Manages LVM physical volumes.

#### Actions

Action  | Description
------- | ---------------------------------------
:create | (default) Creates a new physical volume
:resize | Resize an existing physical volume

#### Parameters

Parameter       | Description                                                                                | Example  | Default
--------------- | ------------------------------------------------------------------------------------------ | -------- | -------
name            | (required) The device to create the new physical volume on                                 | /dev/sda |
wipe_signatures | Force the creation of the Logical Volume, even if `lvm` detects existing PV signatures/td> | `true`   | `false`

#### Examples

```ruby
lvm_physical_volume '/dev/sda'
```

--------------------------------------------------------------------------------

### lvm_logical_volume

Manages LVM logical volumes.

#### Actions

Action  | Description
------- | --------------------------------------
:create | (default) Creates a new logical volume
:resize | Resize an existing logical volume

#### Parameters
<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
    <th>Example</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>name</td>
    <td>(name attribute) Name of the logical volume</td>
    <td><tt>bacon</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>group</td>
    <td>(required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block)</td>
    <td><tt>bits</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>size</td>
    <td>(required) Size of the volume.
      <ul>
        <li>It can be the size of the volume with units (k, K, m, M, g, G, t, T)</li>
        <li>It can be specified as the percentage of the size of the volume group</li>
      </ul>
    </td>
    <td>
      <ul>
        <li><tt>10G</tt></li>
        <li><tt>25%VG</tt></li>
      </ul>
    </td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem</td>
    <td>The format for the file system</td>
    <td><tt>'ext4'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem_params</td>
    <td>Optional parameters to use when formatting the file system</td>
    <td><tt>'-j -L log -m 2 -i 10240 -J size=400 -b 4096'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mount_point</td>
    <td>
      Either a String containing the path to the mount point, or a Hash with the following keys:
      <ul>
        <li>driver:
  name: dokken
  privileged: true # because Docker and SystemD/Upstart
  chef_version: current - (required) the directory to mount the volume on</li>
        <li><tt>options</tt> - the mount options for the volume</li>
        <li><tt>dump</tt> - the <tt>dump</tt> field for the fstab entry</li>
        <li><tt>pass</tt> - the <tt>pass</tt> field for the fstab entry</li>
      </ul>
    </td>
    <td><tt>'/var/my/mount'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>physical_volumes</td>
    <td>Array of physical volumes that the volume will be
  restricted to</td>
    <td><tt>['/dev/sda', '/dev/sdb']</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>stripes</td>
    <td>Number of stripes for the volume</td>
    <td><tt>5</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>stripe_size</td>
    <td>Number of kilobytes per stripe segment (must be a power of 2 less than or equal to the physical extent size for the volume group)</td>
    <td><tt>24</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mirrors</td>
    <td>Number of mirrors for the volume</td>
    <td><tt>5</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>contiguous</td>
    <td>Whether or not volume should use the contiguous allocation
  policy</td>
    <td><tt>true</tt></td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td>readahead</td>
    <td>The readahead sector count for the volume (can be a value
  between 2 and 120, 'auto', or 'none')</td>
    <td><tt>'auto'</tt></td>
    <td></td>
  </tr>
  <td>take_up_free_space</td>
    <td>whether to have the LV take up the remainder of free space on the VG. Only valid for resize action</td>
    <td><tt>true</tt></td>
    <td>false</td>
  </tr>
  <tr>
    <td>wipe_signatures</td>
    <td>Force the creation of the Logical Volume, even if `lvm` detects existing LV signatures/td>
    <td>`true`</td>
    <td>`false`</td>
  </tr>
</table>

#### Examples

```ruby
lvm_logical_volume 'home' do
  group       'vg00'
  size        '25%VG'
  filesystem  'ext4'
  mount_point '/home'
  stripes     3
  mirrors     2
end
```

---


### lvm_thin_pool
Manages LVM thin pools (which are simply logical volumes created with the --thinpool argument to lvcreate).

#### Actions
<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>:create</td>
    <td>(default) Create a new thin pool logical volume</td>
  </tr>
  <tr>
    <td>:resize</td>
    <td>Resize an existing thin pool logical volume</td>
  </tr>
</table>

#### Parameters
<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
    <th>Example</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>name</td>
    <td>(name attribute) Name of the logical volume</td>
    <td><tt>bacon</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>group</td>
    <td>(required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block)</td>
    <td><tt>bits</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>size</td>
    <td>(required) Size of the volume.
      <ul>
        <li>It can be the size of the volume with units (k, K, m, M, g, G, t, T)</li>
        <li>It can be specified as the percentage of the size of the volume group</li>
      </ul>
    </td>
    <td>
      <ul>
        <li><tt>10G</tt></li>
        <li><tt>25%VG</tt></li>
      </ul>
    </td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem</td>
    <td>The format for the file system</td>
    <td><tt>'ext4'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem_params</td>
    <td>Optional parameters to use when formatting the file system</td>
    <td><tt>'-j -L log -m 2 -i 10240 -J size=400 -b 4096'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mount_point</td>
    <td>
      Either a String containing the path to the mount point, or a Hash with the following keys:
      <ul>
        <li>driver:
  name: dokken
  privileged: true # because Docker and SystemD/Upstart
  chef_version: current - (required) the directory to mount the volume on</li>
        <li><tt>options</tt> - the mount options for the volume</li>
        <li><tt>dump</tt> - the <tt>dump</tt> field for the fstab entry</li>
        <li><tt>pass</tt> - the <tt>pass</tt> field for the fstab entry</li>
      </ul>
    </td>
    <td><tt>'/var/my/mount'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>physical_volumes</td>
    <td>Array of physical volumes that the volume will be
  restricted to</td>
    <td><tt>['/dev/sda', '/dev/sdb']</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>stripes</td>
    <td>Number of stripes for the volume</td>
    <td><tt>5</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>stripe_size</td>
    <td>Number of kilobytes per stripe segment (must be a power of 2 less than or equal to the physical extent size for the volume group)</td>
    <td><tt>24</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mirrors</td>
    <td>Number of mirrors for the volume</td>
    <td><tt>5</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>contiguous</td>
    <td>Whether or not volume should use the contiguous allocation
  policy</td>
    <td><tt>true</tt></td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td>readahead</td>
    <td>The readahead sector count for the volume (can be a value
  between 2 and 120, 'auto', or 'none')</td>
    <td><tt>'auto'</tt></td>
    <td></td>
  </tr>
  <td>take_up_free_space</td>
    <td>whether to have the LV take up the remainder of free space on the VG. Only valid for resize action</td>
    <td><tt>true</tt></td>
    <td>false</td>
  </tr>
  <tr>
    <td>thin_volume</td>
    <td>Shortcut for creating a new `lvm_thin_volume` definition (the volumes will be created in the order they are declared)</td>
    <td></td>
    <td></td>
 </tr>
</table>

---


### lvm_thin_volume
Manages LVM thin volumes (which are simply logical volumes created with the --thin argument to lvcreate and are contained inside of
other logical volumes that were created with the --thinpool option to lvcreate).

#### Actions
<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>:create</td>
    <td>(default) Create a new thin logical volume</td>
  </tr>
  <tr>
    <td>:resize</td>
    <td>Resize an existing thin logical volume</td>
  </tr>
</table>

#### Parameters
<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
    <th>Example</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>name</td>
    <td>(name attribute) Name of the logical volume</td>
    <td><tt>bacon</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>group</td>
    <td>(required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block)</td>
    <td><tt>bits</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>pool</td>
    <td>(required) Thin pool volume in which to create the new volume (not required if the volume is declared inside of an `lvm_thin_pool` block)</td>
    <td><tt>bits</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>size</td>
    <td>(required) Size of the volume.
      <ul>
        <li>It can be the size of the volume with units (k, K, m, M, g, G, t, T)</li>
      </ul>
    </td>
    <td>
      <ul>
        <li><tt>10G</tt></li>
      </ul>
    </td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem</td>
    <td>The format for the file system</td>
    <td><tt>'ext4'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem_params</td>
    <td>Optional parameters to use when formatting the file system</td>
    <td><tt>'-j -L log -m 2 -i 10240 -J size=400 -b 4096'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mount_point</td>
    <td>
      Either a String containing the path to the mount point, or a Hash with the following keys:
      <ul>
        <li>driver:
  name: dokken
  privileged: true # because Docker and SystemD/Upstart
  chef_version: current - (required) the directory to mount the volume on</li>
        <li><tt>options</tt> - the mount options for the volume</li>
        <li><tt>dump</tt> - the <tt>dump</tt> field for the fstab entry</li>
        <li><tt>pass</tt> - the <tt>pass</tt> field for the fstab entry</li>
      </ul>
    </td>
    <td><tt>'/var/my/mount'</tt></td>
    <td></td>
  </tr>
</table>


#### Examples

```ruby
lvm_thin_volume 'thin01' do
  group       'vg00'
  pool        'lv-thin-pool'
  size        '5G'
  filesystem  'ext4'
  mount_point location: '/var/thin01', options: 'noatime,nodiratime'
end
```

--------------------------------------------------------------------------------

### lvm_volume_group

Manages LVM volume groups.

#### Actions

Action  | Description
------- | ---------------------------------------------------------------
:create | (default) Creates a new volume group
:extend | Extend an existing volume group to include new physical volumes

#### Parameters

Attribute            | Description                                                                                                                                                                | Example                           | Default
-------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | -------
name                 | (required) Name of the volume group                                                                                                                                        | <tt>'bacon'</tt>                  |
physical_volumes     | (required) The device or list of devices to use as physical volumes (if they haven't already been initialized as physical volumes, they will be initialized automatically) | <tt>['/dev/sda', '/dev/sdb']</tt> |
physical_extent_size | The physical extent size for the volume group                                                                                                                              |                                   |
logical_volume       | Shortcut for creating a new `lvm_logical_volume` definition (the logical volumes will be created in the order they are declared)                                           |                                   |
wipe_signatures      | Force the creation of the Volume Group, even if `lvm` detects existing non-LVM data on disk                                                                                | `true`                            | `false`
thin_pool            | Shortcut for creating a new `lvm_thin_pool` definition (the logical volumes will be created in the order they are declared)                                                |                                   |

#### Examples

```ruby
lvm_volume_group 'vg00' do
  physical_volumes ['/dev/sda', '/dev/sdb', '/dev/sdc']
  wipe_signatures true

  logical_volume 'logs' do
    size        '1G'
    filesystem  'xfs'
    mount_point location: '/var/log', options: 'noatime,nodiratime'
    stripes     3
  end

  logical_volume 'home' do
    size        '25%VG'
    filesystem  'ext4'
    mount_point '/home'
    stripes     3
    mirrors     2
  end

  thin_pool "lv-thin-pool" do
    size '5G'
    stripes 2

    thin_volume "thin01" do
      size '10G'
      filesystem  'ext4'
      mount_point location: '/var/thin01', options: 'noatime,nodiratime'
    end
  end
end
```

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

## License and Authors

- Author:: Joshua Timberman [joshua@chef.io](mailto:joshua@chef.io)
- Author:: Greg Symons [gsymons@drillinginfo.com](mailto:gsymons@drillinginfo.com)

```text
Copyright:: 2011-2016, Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
