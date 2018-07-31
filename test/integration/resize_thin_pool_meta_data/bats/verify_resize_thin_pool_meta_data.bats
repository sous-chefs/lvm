#!/usr/bin/env bats

@test "resizes the thin pool metadata volume 'lv-thin-pool_tmeta' to 128m" {
  metadata_size="$(lvs --options meta_data_lv,lv_metadata_size|awk '/lv-thin_tmeta/ {print $2}')"
  [ "$metadata_size" == "128.00m" ]
}
