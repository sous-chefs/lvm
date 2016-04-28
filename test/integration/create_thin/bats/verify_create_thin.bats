#!/usr/bin/env bats

@test "creates the physical volumes" {
  pvs | grep /dev/loop0
  pvs | grep /dev/loop1
  pvs | grep /dev/loop2
  pvs | grep /dev/loop3
}

@test "creates the thin pool logical volume tpool on vg-data" {
  lvs | grep tpool | grep vg-data
}

@test "creates the thin logical volume tvol01 on tpool on vg-data" {
  lvs | grep tvol01 | grep vg-data | grep tpool
}

@test "creates the thin logical volume tvol02 on tpool on vg-data" {
  lvs | grep tvol02 | grep vg-data | grep tpool
}

@test "mounts the logical volume 'tvol01' to '/mnt/tvol01'" {
  mountpoint /mnt/tvol01
  mount | grep /dev/mapper/vg--data-tvol01 | grep /mnt/tvol01
}

@test "mounts the logical volume 'tvol02' to '/mnt/tvol02'" {
  mountpoint /mnt/tvol02
  mount | grep /dev/mapper/vg--data-tvol02 | grep /mnt/tvol02
}

@test "thin volume 'tvol01' is formatted as 'ext2' filesystem" {
  blkid /dev/mapper/vg--data-tvol01 | grep "TYPE=\"ext2\""
}

@test "thin volume 'tvol02' is formatted as 'ext2' filesystem" {
  blkid /dev/mapper/vg--data-tvol02 | grep "TYPE=\"ext2\""
}

@test "creates the logical volume 'tvol01' with a size of 40 MiB" {
  lvsize="$(lvdisplay /dev/vg-data/tvol01|awk '/LV Size/ {print $3 $4}')"
  [ "$lvsize" == "40.00MiB" ]
}

@test "creates the logical volume 'tvol02' with a size of 1 GiB" {
  lvsize="$(lvdisplay /dev/vg-data/tvol02|awk '/LV Size/ {print $3 $4}')"
  [ "$lvsize" == "1.00GiB" ]
}
