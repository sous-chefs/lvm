#!/usr/bin/env bats

# On CentOS 5.9, most of the commands used here are not in PATH. So add them
# here.
export PATH=$PATH:/sbin:/usr/sbin

@test "creates the physical volume" {
  pvs | grep /dev/loop0
}

@test "creates the volume group" {
  vgs | grep vg-data
}

@test "creates the logical volume" {
  lvs | grep test
}

@test "logical volume is formatted as ext3 filesystem" {
  blkid /dev/mapper/vg--data-test | grep "TYPE=\"ext3\""
}

@test "mounts the logical volume to /mnt/test" {
  mountpoint /mnt/test
  mount | grep /dev/mapper/vg--data-test | grep /mnt/test
}
