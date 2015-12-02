#!/usr/bin/env bats

# On CentOS 5.9, most of the commands used here are not in PATH. So add them
# here.
export PATH=$PATH:/sbin:/usr/sbin

@test "detects notification for creation of small_resize volume" {
  grep 'volume small_resize has been created' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'volume small_resize has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "detects notification for resize of small_resize volume" {
  grep 'volume small_resize has been resized' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'volume small_resize has been resized' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "creates the logical volume using 5% of the available vg extents and resizes to 10%" {
  vgsize="$(vgdisplay vg-test|awk '/Total PE/ {print $3}')"
  lvsize="$(lvdisplay /dev/mapper/vg--test-percent_resize|awk '/Current LE/ {print $3}')"
  vg2pct="$( expr $vgsize / 10 )"
  [ "$lvsize" -ge "$vg2pct" ]
}

@test "detects notification for creation of percent_resize volume" {
  grep 'volume percent_resize has been created' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'volume percent_resize has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "detects notification for resize of percent_resize volume" {
  grep 'volume percent_resize has been resized' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'volume percent_resize has been resized' /tmp/test_notifications | wc -l) -eq 1 ]
}

@test "creates the logical volume using 5% of the available vg extents and does not resize" {
  vgsize="$(vgdisplay vg-test|awk '/Total PE/ {print $3}')"
  lvsize="$(lvdisplay /dev/mapper/vg--test-percent_noresize|awk '/Current LE/ {print $3}')"
  vg2pct="$( expr $vgsize / 20 )"
  [ "$lvsize" -ge "$vg2pct" ]
}

@test "detects notification for creation of percent_noresize volume" {
  grep 'volume percent_noresize has been created' /tmp/test_notifications
  [ $(grep 'volume percent_noresize has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

# TODO: Fix This
# @test "does not detect notification for creation of percent_noresize volume" {
#   ! grep 'volume percent_noresize has been resized' /tmp/test_notifications
# }

@test "creates the logical volume at 8MB and resizes to 16MB" {
  # 8MB LV size / 4MB default extent size
  num_extents="4"
  lvsize="$(lvdisplay /dev/mapper/vg--test-small_resize|awk '/Current LE/ {print $3}')"
  [ "$lvsize" -ge "$num_extents" ]
}

@test "creates the logical volume at 8MB and does not resize" {
  # 8MB LV size / 4MB default extent size
  num_extents="2"
  lvsize="$(lvdisplay /dev/mapper/vg--test-small_noresize|awk '/Current LE/ {print $3}')"
  [ "$lvsize" -ge "$num_extents" ]
}

@test "detects notification for creation of small_noresize volume" {
  grep 'volume small_noresize has been created' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'volume small_noresize has been created' /tmp/test_notifications | wc -l) -eq 1 ]
}

# TODO: Fix This
# @test "does not detects notification for resize of small_noresize volume" {
#   ! grep 'volume small_noresize has been resized' /tmp/test_notifications
# }

@test "creates and resizes a logical volume that fills the VG" {
  num_extents="36"
  lvsize="$(lvdisplay /dev/mapper/vg--test-remainder_resize|awk '/Current LE/ {print $3}')"
  [ "$lvsize" -ge "$num_extents" ]
}

@test "verifies the VG has no more extents left" {
  num_extents="0"
  lvsize="$(vgdisplay vg-test -c | cut -d: -f16)"
  [ "$lvsize" -ge "$num_extents" ]
}


@test "resizes the PV to fill the remaining space" {
  num_extents="39"
  lvsize="$(pvdisplay /dev/loop0 -c | cut -d: -f9)"
  [ "$lvsize" -eq "$num_extents" ]
}

@test "detects notification for creation of remainder_resize volume" {
  grep 'volume remainder_resize has been created/resized' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'volume remainder_resize has been created/resized' /tmp/test_notifications | wc -l) -eq 1 ]
}

