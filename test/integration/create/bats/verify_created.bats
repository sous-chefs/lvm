#!/usr/bin/env bats

@test "creates the physical volume" {
  pvs | grep /dev/loop0
}

@test "creates the volume group" {
  vgs | grep vg-data
}

@test "creates the logical volume" {
  lvs | grep test
}

@test "logical volume is formatted as ext4 filesystem" {
  blkid /dev/mapper/vg--data-test | grep "TYPE=\"ext4\""
}

@test "mounts the logical volume to /mnt/test" {
  mountpoint /mnt/test
  mount | grep /dev/mapper/vg--data-test | grep /mnt/test | grep ext4
}
