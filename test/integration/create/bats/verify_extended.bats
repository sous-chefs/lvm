#!/usr/bin/env bats

# On CentOS 5.9, most of the commands used here are not in PATH. So add them
# here.
export PATH=$PATH:/sbin:/usr/sbin

@test "extends the volume group" {
  pvdisplay -c /dev/loop7 | cut -d: -f2 | grep -q "vg-test"
}

@test "detects notification for extention of vg-data" {
  grep 'vg-test has been extended' /tmp/test_notifications
  # TODO: Fix This [ $(grep 'vg-test has been extended' /tmp/test_notifications | wc -l) -eq 1 ]
}
