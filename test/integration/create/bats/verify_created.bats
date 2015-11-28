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
  pvs | grep /dev/loop5
  pvs | grep /dev/loop6
  pvs | grep /dev/loop7
}

@test "detects notification for physical volume creation" {
  grep 'pv for /dev/loop0 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop1 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop2 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop3 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop4 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop5 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop6 has been created' /tmp/test_notifications
  grep 'pv for /dev/loop7 has been created' /tmp/test_notifications
  # TODO: Fix these
  # [ $(grep 'pv for /dev/loop0 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop1 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop2 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop3 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop4 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop5 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop6 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
  # [ $(grep 'pv for /dev/loop7 has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "creates the volume group vg-data" {
  vgs | grep vg-data
}

@test "detects notification for creation of vg-data" {
  grep 'vg-data has been created' /tmp/test_notifications
  [ $(grep 'vg-data has been created' /tmp/test_notifications | wc -l) -eq 1 ]
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

# TODO: Fix This
# @test "detects notification for creation of logs volume" {
#   grep 'logs volume has been created' /tmp/test_notifications
#   [ $(grep 'logs volume has been created' /tmp/test_notifications | wc -l) -eq 1 ]
# }

@test "creates the logical volume home on vg-data" {
  lvs | grep home | grep vg-data
}

@test "logical volume home is formatted as ext2 filesystem" {
  blkid /dev/mapper/vg--data-home | grep "TYPE=\"ext2\""
}

# TODO: Fix This
# @test "mounts the logical volume home to /mnt/home" {
#   mountpoint /mnt/home
#   mount | grep /dev/mapper/vg--data-home | grep /mnt/home
# }

# TODO: Fix This
# @test "detects notification for creation of home volume" {
#   grep 'home volume has been created' /tmp/test_notifications
#   [ $(grep 'home volume has been created' /tmp/test_notifications | wc -l) -eq 1 ]
# }

@test "creates the volume group vg-test" {
  vgs | grep vg-test
}

@test "detects notification for creation of vg-data" {
  grep 'vg-test has been created' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'vg-test has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "creates the logical volume 'test' on 'vg-test'" {
  lvs | grep test | grep vg-test
}

@test "detects notification for creation of test volume" {
  grep 'test volume has been created' /tmp/test_notifications
  [ $(grep 'test volume has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "logical volume 'test' is formatted as 'ext3' filesystem" {
  blkid /dev/mapper/vg--test-test | grep "TYPE=\"ext3\""
}

@test "mounts the logical volume to /mnt/test" {
  mountpoint /mnt/test
  mount | grep /dev/mapper/vg--test-test | grep /mnt/test
}

@test "detects notification for creation of test volume" {
  grep 'test volume has been created' /tmp/test_notifications
  [ $(grep 'test volume has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "creates the logical volume 'small' on 'vg-test'" {
  lvs | grep small | grep vg-test
}

@test "logical volume 'test' is formatted as 'ext3' filesystem" {
  blkid /dev/mapper/vg--test-small | grep "TYPE=\"ext3\""
}

@test "mounts the logical volume to /mnt/small" {
  mountpoint /mnt/small
  mount | grep /dev/mapper/vg--test-small | grep /mnt/small
}

@test "creates the logical volume using 2% of the available vg extents" {
  vgsize="$(vgdisplay vg-test|awk '/Total PE/ {print $3}')"
  lvsize="$(lvdisplay /dev/mapper/vg--test-small|awk '/Current LE/ {print $3}')"
  vg2pct="$(( $vgsize/50 ))"
  [ "$lvsize" -ge "$vg2pct" ]
}

@test "mode of mounted file systems should match the directory setting" {
  ls -la /mnt/small | grep "dr-xr-xr-x"
}

@test "Exposed mount point mode should be 755" {
  umount /mnt/small
  ls -la /mnt/small | grep "drwxr-xr-x"
}

@test "Remount works using fstab information" {
  mount /mnt/small
  mount | grep /dev/mapper/vg--test-small | grep /mnt/small
}

@test "detects notification for creation of small volume" {
  grep 'small volume has been created' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'small volume has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}
