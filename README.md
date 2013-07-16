LVM Cookbook and LWRP
=====================
Installs lvm2 package and includes resources for managing LVM. The default recipe simply installs LVM and the supporting Ruby gem. The cookbok includes and LWRP for managing LVMs.


Requirements
------------
- Chef 10 or higher


LWRPs
-----
#### `lvm_physical_volume`
Manages LVM physical volumes.

##### Actions
<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>:create</td>
    <td>(default) Creates a new physical volume</td>
  </tr>
</table>

##### Parameters
<table>
  <tr>
    <th>Parameter</th>
    <th>Description</th>
    <th>Example</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>name</td>
    <td>(required) device to create the new physical volume on</td>
    <td><tt>'bacon'</tt></td>
    <td></td>
  </tr>
</table>

##### Examples
```ruby
lvm_physical_volume '/dev/sda'
```

---


#### `lvm_logical_volume`
Manages LVM logical volumes.

##### Actions
<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>:create</td>
    <td>(default) CCreates a new logical volume</td>
  </tr>
</table>

##### Parameters
<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
    <th>Example</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>name</td>
    <td>(name attribute) name of the logical volume</td>
    <td><tt>bacon</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>group</td>
    <td>(required) volume group in which to create the new volume (required unless the volume is declared inside of an `lvm_volume_group` block)</td>
    <td><tt>bits</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>size</td>
    <td>(required) size of the volume</td>
    <td><tt>10G</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>filesystem</td>
    <td>format for the file system</td>
    <td><tt>'ntfs'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mount_point</td>
    <td>
      either a string containing the path to the mount point, or Hash containing the following keys:
      <ul>
        <li>`location` - (required) the directory to mount the volume on</li>
        <li>`options` - the mount options for the volume</li>
        <li>`dump` - the `dump` field for the fstab entry</li>
        <li>`pass` - the `pass` field for the fstab entry</li>
      </ul>
    </td>
    <td><tt>'/var/my/mount'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>physical_volumes</td>
    <td>array of physical volumes that the volume will be
  restricted to</td>
    <td><tt>['/u01']</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>stripes</td>
    <td>number of stripes for the volume</td>
    <td><tt>5</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>stripe_size</td>
    <td>number of kilobytes per stripe segment (must be a power of 2 less than or equal to the physical extent size for the volume group)</td>
    <td><tt>24</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>mirrors</td>
    <td>number of mirrors for the volume</td>
    <td><tt>5</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>contiguous</td>
    <td>whether or not volume should use the contiguous allocation
  policy</td>
    <td><tt>true</tt></td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td>readahead</td>
    <td>readahead sector count for the volume (can be a value
  between 2 and 120, 'auto', or 'none')</td>
    <td><tt>'auto'</tt></td>
    <td></td>
  </tr>
</table>

##### Examples

```ruby
lvm_logical_volume 'home' do
  group 'vg00'
  size '25%VG'
  filesystem 'ext4'
  mount_point '/home'
  stripes 3
  mirrors 2
end
```

---


#### `lvm_volume_group`
Manages LVM volume groups.

##### Actions
<table>
  <tr>
    <th>Action</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>:create</td>
    <td>(default) Creates a new volume group</td>
  </tr>
</table>

##### Parameters
<table>
  <tr>
    <th>Attribute</th>
    <th>Description</th>
    <th>Example</th>
    <th>Default</th>
  </tr>
  <tr>
    <td>name</td>
    <td>(required) name of the volume group</td>
    <td><tt>'bacon'</tt></td>
    <td></td>
  </tr>
  <tr>
    <td>physical_volumes</td>
    <td>(required) device or list of devices to use as physical volumes (if theyhaven't already been initialized as physical volumes, they will be initialized automatically)</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>physical_extent_size</td>
    <td>physical extent size for the volume group</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>logical_volume</td>
    <td>shortcut for creating a new `lvm_logical_volume` definition (the logical volumes will be created in the order they are declared)</td>
    <td></td>
    <td></td>
  </tr>
</table>

##### Examples
```ruby
lvm_volume_group 'vg00' do
  physical_volumes [g'/dev/sda', '/dev/sdb', '/dev/sdc']

  logical_volume 'logs' do
    size '1G'
    filesystem 'xfs'
    mount_point :location => '/var/log', :options => 'noatime,nodiratime'
    stripes 3
  end

  logical_volume 'home' do
    size '25%VG'
    filesystem 'ext4'
    mount_point '/home'
    stripes 3
    mirrors 2
  end
end
```


Usage
-----
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

Depend on `lvm` in any cookbook that uses its LWRP:

```ruby
# other_cookbook/metadata.rb
depends 'lvm'
```


Caveats
-------
This cookbook depends on the [di-ruby-lvm](https://github.com/DrillingInfo/di-ruby-lvm) and [di-ruby-lvm-attrib](https://github.com/DrillingInfo/di-ruby-lvm-attrib) gems. The di-ruby-lvm-attrib gem in particular is a common cause of failures when using the providers. If you get a failure with an error message similar to

```text
No such file or directory - /opt/chef/.../di-ruby-lvm-attrib-0.0.3/lib/lvm/attributes/2.02.86(2)/lvs.yaml
```

then you are running a version of lvm that the gems do not support. However, getting support added is usually pretty easy. Just follow the instructions on "Adding Attributes" in the [di-ruby-lvm-attrib README](https://github.com/DrillingInfo/di-ruby-lvm-attrib).


License and Authors
-------------------
- Author:: Joshua Timberman <joshua@opscode.com>
- Author:: Greg Symons <gsymons@drillinginfo.com>


Copyright:: 2011, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
