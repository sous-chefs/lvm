#!/usr/bin/env bats

# On CentOS 5, most of the commands used here are not in PATH. So add them
# here.
export PATH=$PATH:/sbin:/usr/sbin

# physical volumes should be setup
@test "creates the physical volumes" {
  pvs | grep /dev/loop10
  pvs | grep /dev/loop11
  pvs | grep /dev/loop12
  pvs | grep /dev/loop13
}

# volume group should be created
@test "creates the volume group vg-rmdata" {
  vgs | grep vg-rmdata
}

# volume group should have all space available
@test "all space is available in the volume group" {
  vsize = vgs | grep vg-rmdata | cut -d' ' -f14
  vfree = vgs | grep vg-rmdata | cut -d' ' -f15
  [ "$vsize" -eq "$vfree" ]
}

# This should not exist, as it was deleted
@test "removes the logical volume rmlogs on vg-rmdata" {
  lvs | grep rmlogs
  [ $status = 0 ]
}

# This should not exist, as it was deleted
@test "removes the logical volume rmtest on vg-rmdata" {
  lvs | grep rmtest
  [ $status = 0 ]
}

@test "mount location should be created for /mnt/rmlogs" {
  ls /mnt | grep rmlogs
}

@test "Exposed mount point mode should be 755" {
  ls -la /mnt/rmlogs | grep "drwxr-xr-x"
}

@test "mount location should NOT be created for /mnt/rmtest, as it was deleted" {
  ls /mnt | grep rmtest
  [ $status = 0 ]
}
