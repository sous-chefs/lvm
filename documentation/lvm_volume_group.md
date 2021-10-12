[Back to resource list](../README.md#resources)

# lvm_volume_group

Manages LVM volume groups.

## Actions

| Action    | Description                                                     |
| --------- | --------------------------------------------------------------- |
| `:create` | (default) Creates a new volume group                            |
| `:extend` | Extend an existing volume group to include new physical volumes |

## Properties

| Name                   | Type            | Default       | Description                                                                                                                                                                |
| ---------------------- | --------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                 | String          | name property | (required) Name of the volume group                                                                                                                                        |
| `physical_volumes`     | Array, String   |               | (required) The device or list of devices to use as physical volumes (if they haven't already been initialized as physical volumes, they will be initialized automatically) |
| `physical_extent_size` | String          | `nil`         | The physical extent size for the volume group                                                                                                                              |
| `logical_volume`       | Proc            | `nil`         | Shortcut for creating a new `lvm_logical_volume` definition (the logical volumes will be created in the order they are declared)                                           |
| `wipe_signatures`      | `true`, `false` | `false`       | Force the creation of the Volume Group, even if `lvm` detects existing non-LVM data on disk                                                                                |
| `thin_pool`            | Proc            | `nil`         | Shortcut for creating a new `lvm_thin_pool` definition (the logical volumes will be created in the order they are declared)                                                |

## Examples

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
