# lvm Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/lvm.svg?branch=master)](https://travis-ci.org/chef-cookbooks/lvm) [![Cookbook Version](https://img.shields.io/cookbook/v/lvm.svg)](https://supermarket.chef.io/cookbooks/lvm)

Installs lvm2 package and includes custom resources (providers) for managing LVM.

## Requirements

### Platforms

- Debian/Ubuntu
- RHEL/CentOS/Scientific/Amazon/Oracle

### Chef

- Chef 12+

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

Parameter | Description                                                | Example             | Default
--------- | ---------------------------------------------------------- | ------------------- | -------
name      | (required) The device to create the new physical volume on | <tt>'/dev/sda'</tt> |

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

Attribute | Description                                                                                                                              | Example        | Default
--------- | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------- | -------
name      | (name attribute) Name of the logical volume                                                                                              | <tt>bacon</tt> |
group     | (required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block) | <tt>bits</tt>  |
size      | (required) Size of the volume.

- It can be the size of the volume with units (k, K, m, M, g, G, t, T)
- It can be specified as the percentage of the size of the volume group | -

  <tt>10G</tt>

- <tt>25%VG</tt>

  | filesystem | The format for the file system |

  <tt>'ext4'</tt>

  | filesystem_params | Optional parameters to use when formatting the file system |

  <tt>'-j -L log -m 2 -i 10240 -J size=400 -b 4096'</tt>

  | mount_point | Either a String containing the path to the mount point, or a Hash with the following keys:

- <tt>location<tt> - (required) the directory to mount the volume on</tt></tt>

<tt>
  <tt>
  <li><tt>options</tt> - the mount options for the volume</li>
  <li><tt>dump</tt> - the <tt>dump</tt> field for the fstab entry</li>
  <li><tt>pass</tt> - the <tt>pass</tt> field for the fstab entry</li>
</tt>
</tt>



<tt>
  <tt>
</tt>
</tt>

|

<tt>'/var/my/mount'</tt>

| physical_volumes | Array of physical volumes that the volume will be restricted to |

<tt>['/dev/sda', '/dev/sdb']</tt>

| stripes | Number of stripes for the volume |

<tt>5</tt>

| stripe_size | Number of kilobytes per stripe segment (must be a power of 2 less than or equal to the physical extent size for the volume group) |

<tt>24</tt>

| mirrors | Number of mirrors for the volume |

<tt>5</tt>

| contiguous | Whether or not volume should use the contiguous allocation policy |

<tt>true</tt>

|

<tt>false</tt>

readahead | The readahead sector count for the volume (can be a value between 2 and 120, 'auto', or 'none') |

<tt>'auto'</tt>

| take_up_free_space | whether to have the LV take up the remainder of free space on the VG. Only valid for resize action |

<tt>true</tt>

| false #### Examples `ruby lvm_logical_volume 'home' do group 'vg00' size '25%VG' filesystem 'ext4' mount_point '/home' stripes 3 mirrors 2 end` -------------------------------------------------------------------------------- ### lvm_thin_pool Manages LVM thin pools (which are simply logical volumes created with the --thinpool argument to lvcreate). #### Actions Action | Description ------- | ----------------------------------------------- :create | (default) Create a new thin pool logical volume :resize | Resize an existing thin pool logical volume #### Parameters Attribute | Description | Example | Default ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ | -------------- name | (name attribute) Name of the logical volume |

<tt>bacon</tt>

| group | (required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block) |

<tt>bits</tt>

| size | (required) Size of the volume. - It can be the size of the volume with units (k, K, m, M, g, G, t, T) - It can be specified as the percentage of the size of the volume group | -

<tt>10G</tt>

- <tt>25%VG</tt>

  | filesystem | The format for the file system |

  <tt>'ext4'</tt>

  | filesystem_params | Optional parameters to use when formatting the file system |

  <tt>'-j -L log -m 2 -i 10240 -J size=400 -b 4096'</tt>

  | mount_point | Either a String containing the path to the mount point, or a Hash with the following keys:

- <tt>location<tt> - (required) the directory to mount the volume on</tt></tt>

<tt>
  <tt>
  <li><tt>options</tt> - the mount options for the volume</li>
  <li><tt>dump</tt> - the <tt>dump</tt> field for the fstab entry</li>
  <li><tt>pass</tt> - the <tt>pass</tt> field for the fstab entry</li>
</tt>
</tt>



<tt>
  <tt>
</tt>
</tt>

|

<tt>'/var/my/mount'</tt>

| physical_volumes | Array of physical volumes that the volume will be restricted to |

<tt>['/dev/sda', '/dev/sdb']</tt>

| stripes | Number of stripes for the volume |

<tt>5</tt>

| stripe_size | Number of kilobytes per stripe segment (must be a power of 2 less than or equal to the physical extent size for the volume group) |

<tt>24</tt>

| mirrors | Number of mirrors for the volume |

<tt>5</tt>

| contiguous | Whether or not volume should use the contiguous allocation policy |

<tt>true</tt>

|

<tt>false</tt>

readahead | The readahead sector count for the volume (can be a value between 2 and 120, 'auto', or 'none') |

<tt>'auto'</tt>

| take_up_free_space | whether to have the LV take up the remainder of free space on the VG. Only valid for resize action |

<tt>true</tt>

| false thin_volume | Shortcut for creating a new `lvm_thin_volume` definition (the volumes will be created in the order they are declared) | | -------------------------------------------------------------------------------- ### lvm_thin_volume Manages LVM thin volumes (which are simply logical volumes created with the --thin argument to lvcreate and are contained inside of other logical volumes that were created with the --thinpool option to lvcreate). #### Actions Action | Description ------- | ------------------------------------------ :create | (default) Create a new thin logical volume :resize | Resize an existing thin logical volume #### Parameters Attribute | Description | Example | Default ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ | ------- name | (name attribute) Name of the logical volume |

<tt>bacon</tt>

| group | (required) Volume group in which to create the new volume (not required if the volume is declared inside of an `lvm_volume_group` block) |

<tt>bits</tt>

| pool | (required) Thin pool volume in which to create the new volume (not required if the volume is declared inside of an `lvm_thin_pool` block) |

<tt>bits</tt>

| size | (required) Size of the volume. - It can be the size of the volume with units (k, K, m, M, g, G, t, T) | -

<tt>10G</tt>

| filesystem | The format for the file system |

<tt>'ext4'</tt>

| filesystem_params | Optional parameters to use when formatting the file system |

<tt>'-j -L log -m 2 -i 10240 -J size=400 -b 4096'</tt>

| mount_point | Either a String containing the path to the mount point, or a Hash with the following keys: -

<tt>location<tt> - (required) the directory to mount the volume on</tt></tt>



<tt>
  <tt>
  <li><tt>options</tt> - the mount options for the volume</li>
  <li><tt>dump</tt> - the <tt>dump</tt> field for the fstab entry</li>
  <li><tt>pass</tt> - the <tt>pass</tt> field for the fstab entry</li>
</tt>
</tt>



<tt>
  <tt>
</tt>
</tt>

|

<tt>'/var/my/mount'</tt>

|

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

If you're using [Berkshelf](http://berkshelf.com), just add this cookbook to your `Berksfile`:

```ruby
cookbook 'lvm'
```

You can also install it from the community site:

```ruby
knife cookbook site install lvm
```

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

This cookbook depends on the [di-ruby-lvm](https://github.com/DrillingInfo/di-ruby-lvm) and [di-ruby-lvm-attrib](https://github.com/DrillingInfo/di-ruby-lvm-attrib) gems. The di-ruby-lvm-attrib gem in particular is a common cause of failures when using the providers. If you get a failure with an error message similar to

```text
No such file or directory - /opt/chef/.../di-ruby-lvm-attrib-0.0.3/lib/lvm/attributes/2.02.86(2)/lvs.yaml
```

then you are running a version of lvm that the gems do not support. However, getting support added is usually pretty easy. Just follow the instructions on "Adding Attributes" in the [di-ruby-lvm-attrib README](https://github.com/DrillingInfo/di-ruby-lvm-attrib).

## License and Authors

- Author:: Joshua Timberman [joshua@chef.io](mailto:joshua@chef.io)
- Author:: Greg Symons [gsymons@drillinginfo.com](mailto:gsymons@drillinginfo.com)

```text
Copyright:: 2011-2015, Chef Software, Inc

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
