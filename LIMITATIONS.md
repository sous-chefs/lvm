# Limitations

## Package Availability

LVM2 is a core Linux kernel subsystem with userspace tools. Packages are available
in the default repositories of all supported Linux distributions — no vendor
repositories are required.

### APT (Debian/Ubuntu)

- `lvm2` — core LVM tools (all versions, amd64 + arm64)
- `thin-provisioning-tools` — required for thin provisioning features
- Debian 12, 13: fully supported
- Ubuntu 22.04, 24.04: fully supported

### DNF/YUM (RHEL family)

- `lvm2` — core LVM tools (all versions, amd64 + arm64)
- `lvm2-libs` — pulled in as a dependency
- AlmaLinux 8, 9, 10: fully supported
- Amazon Linux 2023: fully supported
- CentOS Stream 9, 10: fully supported
- Fedora (current): fully supported
- Oracle Linux 8, 9, 10: fully supported
- RHEL 8, 9, 10: fully supported
- Rocky Linux 8, 9, 10: fully supported

### Zypper (SUSE)

- `lvm2` — core LVM tools
- openSUSE Leap 15: fully supported

## Architecture Limitations

LVM2 packages are available for all architectures supported by each distribution
(amd64, arm64, ppc64le, s390x where applicable). No architecture-specific
limitations exist.

## Kernel Requirements

LVM2 requires the Linux kernel device-mapper subsystem. This has implications for
container-based testing:

- **Dokken (Docker)**: Containers must run in **privileged mode** to access
  device-mapper. The `kitchen.dokken.yml` sets `privileged: true` for this reason
- **Loop devices**: Integration tests create loop devices for testing, which also
  require privileged access
- **Non-Linux**: LVM2 is Linux-specific. FreeBSD, macOS, and Windows are not
  supported

## Platform Support Gaps in metadata.rb

The following platforms are active but missing from `metadata.rb`:

| Platform      | Active Versions | metadata.rb Name |
|---------------|-----------------|------------------|
| AlmaLinux     | 8, 9, 10        | `almalinux`      |
| CentOS Stream | 9, 10           | `centos_stream`  |
| Debian        | 12, 13          | `debian`         |
| Rocky Linux   | 8, 9, 10        | `rocky`          |

The following platforms in `metadata.rb` are EOL or unsupported:

| Platform     | Reason                                           |
|--------------|--------------------------------------------------|
| `centos`     | CentOS (non-stream) is EOL; use `centos_stream`  |
| `freebsd`    | LVM2 is Linux-specific; FreeBSD uses ZFS/gpart   |
| `scientific` | Scientific Linux is EOL                          |
| `suse`       | SLES; only openSUSE Leap (`opensuseleap`) tested |

## Known Issues

- The cookbook depends on `chef-ruby-lvm` and `chef-ruby-lvm-attrib` gems which
  are installed at converge time via `chef_gem`. These gem versions are currently
  managed through node attributes (`attributes/default.rb`), which should be
  converted to resource properties
- The `lvm2-lvmetad` service management in `recipes/default.rb` references
  RHEL 7 which is EOL — this code path is dead
- Ubuntu 20.04 reached EOL in April 2025 and should be removed from testing
