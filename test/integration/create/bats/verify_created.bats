#!/usr/bin/env bats

# On CentOS 5.9, most of the commands used here are not in PATH. So add them
# here.
export PATH=$PATH:/sbin:/usr/sbin

@test "creates the physical volumes" {
  pvs | grep /dev/loop0
  pvs | grep /dev/loop1
  pvs | grep /dev/loop2
  pvs | grep /dev/loop3
  pvs | grep /dev/loop4
}

@test "creates the volume group vg-data" {
  vgs | grep vg-data
}

@test "creates the logical volume logs on vg-data" {
  lvs | grep logs | grep vg-data
}

@test "logical volume logs is formatted as ext2 filesystem" {
  blkid /dev/mapper/vg--data-logs | grep "TYPE=\"ext2\""
}

@test "mounts the logical volume logs to /mnt/logs" {
  mountpoint /mnt/logs
  mount | grep /dev/mapper/vg--data-logs | grep /mnt/logs
}

@test "creates the logical volume home on vg-data" {
  lvs | grep home | grep vg-data
}

@test "logical volume home is formatted as ext2 filesystem" {
  blkid /dev/mapper/vg--data-home | grep "TYPE=\"ext2\""
}

@test "mounts the logical volume home to /mnt/home" {
  mountpoint /mnt/home
  mount | grep /dev/mapper/vg--data-home | grep /mnt/home
}

@test "creates the volume group vg-test" {
  vgs | grep vg-test
}

@test "creates the logical volume 'test' on 'vg-test'" {
  lvs | grep test | grep vg-test
}

@test "logical volume 'test' is formatted as 'ext3' filesystem" {
  blkid /dev/mapper/vg--test-test | grep "TYPE=\"ext3\""
}

@test "mounts the logical volume to /mnt/test" {
  mountpoint /mnt/test
  mount | grep /dev/mapper/vg--test-test | grep /mnt/test
}
