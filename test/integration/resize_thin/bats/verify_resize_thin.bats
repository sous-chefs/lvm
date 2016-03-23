#!/usr/bin/env bats

@test "resizes the thin logical volume 'thin_vol_1' to 32 MiB" {
  lvsize="$(lvdisplay /dev/vg-test/thin_vol_1|awk '/LV Size/ {print $3 $4}')"
  [ "$lvsize" == "32.00MiB" ]
}
