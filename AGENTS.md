# AGENTS.md — AI Contributor Guide for the lvm Cookbook

This file provides context and constraints for AI coding agents working on this cookbook.

## Architecture Overview

This is a **resource-driven** Chef cookbook with **zero external gem dependencies**. All LVM
state queries use LVM2's built-in `--reportformat json` (available since LVM2 2.02.158, 2017).

### Key Components

- `libraries/lvm.rb` — `LVMCookbook` module with JSON-based LVM query helpers
- `resources/` — Custom resources: `lvm_physical_volume`, `lvm_volume_group`, `lvm_logical_volume`,
  `lvm_thin_pool`, `lvm_thin_volume`, `lvm_thin_pool_meta_data`
- `resources/_partial/` — Shared resource properties
- `test/integration/` — InSpec integration test profiles
- `test/cookbooks/test/` — Test cookbook with recipes exercising all resources
- `spec/unit/` — ChefSpec unit tests

### LVM Command Conventions

All LVM queries use these flags for consistent, parseable output:

```
--reportformat json --units b --nosuffix
```

- `--reportformat json` — structured output (no fragile text parsing)
- `--units b` — all sizes in bytes (no ambiguous suffixes)
- `--nosuffix` — bare numbers (no "B" or "b" suffix)

Field selectors are **explicit** (never use `*_all` meta-fields like `pv_all`, `vg_all`, `lv_all`)
because not all fields exist across all LVM2 versions and cause exit code 5 errors.

Server-side filtering with `--select 'field=value'` is preferred over client-side Ruby filtering.

### JSON Report Structure

LVM2 JSON output wraps data in:
```json
{
  "report": [
    {
      "pv": [ {...}, {...} ],
      "vg": [ {...}, {...} ],
      "lv": [ {...}, {...} ]
    }
  ]
}
```

The report keys are **singular**: `'pv'`, `'vg'`, `'lv'` (not `'pvs'`, `'vgs'`, `'lvs'`).

## Platform & Kernel Requirements

### Supported Platforms

- AlmaLinux 8, 9, 10
- Amazon Linux 2023
- CentOS Stream 9, 10
- Debian 12, 13
- Fedora (latest)
- openSUSE Leap 15
- Oracle Linux 8, 9, 10
- RHEL 8, 9, 10
- Rocky Linux 8, 9, 10
- Ubuntu 22.04, 24.04

### LVM2 is Linux-Only

LVM2 requires the Linux kernel device-mapper subsystem. FreeBSD, macOS, and Windows are **not
supported**. The `lvm2` package is in default repositories of all supported distributions — no
vendor repositories are needed.

### Thin Provisioning

The `thin-provisioning-tools` package is required for thin pool/volume features. On Debian/Ubuntu
it must be explicitly installed; on RHEL-family it's typically pulled in as a weak dependency of
`lvm2`.

## Testing Constraints

### No Docker/Dokken

LVM operations require kernel-level device-mapper access. Containers **cannot** provide this
reliably — even privileged containers have issues with loop devices and device-mapper in CI
environments. Integration tests use **Vagrant + VirtualBox** (or equivalent VM-based drivers).

### Loop Devices for Testing

Integration tests create loop-backed block devices for LVM testing. The test cookbook uses the
`LOOP_CTL_ADD` ioctl on `/dev/loop-control` to allocate specific loop device numbers, then
associates them with file-backed images. This requires a real kernel, not a container namespace.

### CI Configuration

- CI uses `kitchen-vagrant` with VirtualBox, not Dokken
- The `ci.yml` workflow uses `sous-chefs/.github/.github/actions/install-workstation@main`
- `KITCHEN_LOCAL_YAML` environment variable is set in CI for platform overrides
- `CHEF_PRODUCT_NAME` should be set to `chef` (not `cinc`) when using Chef Workstation

### Policyfile Strategy

This cookbook uses a **single `Policyfile.rb`** with **named run lists** for different test
suites (not separate Policyfiles per suite). In `kitchen.yml`, suites reference their named
run list directly at the suite level with `named_run_list:`.

## Development Guidelines

### Resource Design Patterns

- Resources use `load_current_value` with LVMCookbook helpers for idempotency
- Guard logic (checking existing state) goes **outside** `converge_by` blocks
- Sub-resources (like `directory`, `mount`) go **outside** `converge_by` blocks
- Only raw LVM shell commands (`pvcreate`, `vgcreate`, `lvcreate`, etc.) go **inside** `converge_by`
- All resources include the `LVMCookbook` module for access to query helpers

### Backward Compatibility

- Do **not** rename resource properties — existing users depend on the current API
- The cookbook version is managed by `release-please` — do not manually edit `metadata.rb`
  version or `CHANGELOG.md`

### Code Style

- Use `cookstyle` (rubocop-chef) for linting — the `.rubocop.yml` requires `rubocop-chef` only
- Do **not** add `rubocop-rspec` — it is not bundled with Chef Workstation 25+ and causes
  cookstyle to abort

### Unit Tests (ChefSpec)

- Spec helper uses `chefspec/policyfile` (not Berkshelf)
- Unit tests stub `shell_out!` to return mock LVM JSON output
- Run with: `chef exec rspec`

### Integration Tests (InSpec)

- Located in `test/integration/<suite>/`
- Each suite has its own InSpec profile matching the kitchen suite name
- Tests validate actual LVM state (pvs, vgs, lvs commands, mount points)

## Historical Context

This cookbook was refactored from a gem-dependent design (`chef-ruby-lvm` + `chef-ruby-lvm-attrib`)
to native JSON parsing. Those gems parsed LVM text output into Ruby objects but required version-
coupled attribute definitions that frequently fell behind LVM2 releases. The `--reportformat json`
approach is self-describing and version-resilient.

The old gems are archived at:
- https://github.com/sous-chefs/chef-ruby-lvm
- https://github.com/sous-chefs/chef-ruby-lvm-attrib
