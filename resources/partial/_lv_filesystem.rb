# frozen_string_literal: true
#
# Resource:: partial: filesystem, mount-point, and LUKS encryption properties.
# Loaded via `use 'partial/_lv_filesystem'` in lvm_logical_volume and lvm_thin_volume.
#
# Filesystem grow notes (kept here so every consumer has the context):
#
#   ext2 / ext3 / ext4
#     resize2fs <device>              — online; device path required
#     RHEL 10: ext4 is DEPRECATED; XFS is the default and recommended filesystem.
#
#   xfs
#     xfs_growfs <mount_point>        — online; mount point required (not device path!)
#                                       XFS CANNOT be shrunk
#     RHEL 10 default filesystem.
#
#   btrfs
#     btrfs filesystem resize max <mount_point>
#                                     — online; mount point required
#                                       lvresize --resizefs / fsadm do NOT support btrfs;
#                                       always use the explicit btrfs command
#     RHEL 10: Technology Preview only (kernel-modules-extra); not for production
#     Ubuntu 26.04: supported + installer-selectable; ext4 remains the default for LVM

property :filesystem, String,
         description: 'Filesystem type to create on the volume ' \
                      '(e.g. "xfs", "ext4", "btrfs"). ' \
                      'RHEL 10 default: xfs (ext4 deprecated). ' \
                      'Ubuntu 26.04 default: ext4. ' \
                      'btrfs requires volume to be mounted for online grow.'

property :filesystem_params, String,
         description: 'Additional flags passed verbatim to mkfs (e.g. "-L mylabel")'

property :mount_point, [String, Hash],
         description: 'Mount point as an absolute path String, or a Hash with keys: ' \
                      ':location (required), :fstype, :options, :dump, :pass'

property :encrypt_with_luks, [true, false], default: false,
                                            description: 'Encrypt the block device with LUKS before creating the filesystem'

property :luks_version, [String, Integer], default: 2,
                                           description: 'LUKS format version: 1 or 2 (default: 2)'

property :password, String, sensitive: true,
                            description: 'Path to a key-file used for LUKS luksFormat and open'
