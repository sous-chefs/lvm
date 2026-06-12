# frozen_string_literal: true
#
# Cookbook:: lvm
# Library:: lvm_action_helpers
#
# Copyright:: 2024, Sous Chefs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ---------------------------------------------------------------------------
# LvmActionHelpers
# ---------------------------------------------------------------------------
# Shared mixin included in every resource's action_class via:
#
#   action_class do
#     include LvmActionHelpers
#   end
#
# Provides three tiers of helpers:
#
#   1. LVM state queries  (current_pvs / current_vgs / current_lvs)
#   2. Command execution  (lvm_command)
#   3. Filesystem helpers (create_filesystem, grow_filesystem, setup_mount_point,
#                          active_device_path, detect_mount_point, luks helpers)
#
# Filesystem grow notes:
#   ext2/3/4 : resize2fs <device>                              — online, device path
#   xfs      : xfs_growfs <mount_point>                        — online, mount point required
#   btrfs    : btrfs filesystem resize max <mount_point>       — online, mount point required
#              NOTE: lvresize --resizefs / fsadm do NOT support btrfs.
# ---------------------------------------------------------------------------

module LvmActionHelpers
  # ==========================================================================
  # 1.  LVM state queries (lazy-cached per converge run)
  # ==========================================================================

  # Hash keyed by pv_name (e.g. "/dev/sdb")
  def current_pvs
    @current_pvs ||= LvmHelper.pvs(->(cmd) { shell_out(cmd) })
  end

  # Hash keyed by vg_name (e.g. "datavg")
  def current_vgs
    @current_vgs ||= LvmHelper.vgs(->(cmd) { shell_out(cmd) })
  end

  # Hash keyed by "vg_name/lv_name" (e.g. "datavg/datalv")
  def current_lvs
    @current_lvs ||= LvmHelper.lvs(->(cmd) { shell_out(cmd) })
  end

  # ==========================================================================
  # 2.  Command execution
  # ==========================================================================

  # Run a mutating LVM command. Raises on non-zero exit.
  # Suppresses spurious fd-inheritance warnings from LVM.
  def lvm_command(command)
    cmd = shell_out!(command, env: { 'LVM_SUPPRESS_FD_WARNINGS' => '1' })
    Chef::Log.debug("LVM command '#{command}' stdout: #{cmd.stdout}")
    cmd
  end

  # ==========================================================================
  # 3.  Filesystem helpers
  # ==========================================================================

  # /dev/mapper path — LVM doubles hyphens in both VG and LV names in the
  # device-mapper name, so "my-vg/my-lv" maps to "/dev/mapper/my--vg-my--lv".
  def lv_mapper_path(vg, lv)
    "/dev/mapper/#{vg.tr('-', '--')}-#{lv.tr('-', '--')}"
  end

  # Returns the effective block device path: LUKS mapper if encrypted, else
  # the standard /dev/mapper path.
  def active_device_path(vg, lv)
    if new_resource.respond_to?(:encrypt_with_luks) && new_resource.encrypt_with_luks
      "/dev/mapper/#{luks_mapper_name(vg, lv)}"
    else
      lv_mapper_path(vg, lv)
    end
  end

  # LUKS mapper name used for both luksFormat/open and the active device path.
  def luks_mapper_name(vg, lv)
    "#{vg}-#{lv}"
  end

  # Open LUKS container if not already open. Call only when encrypt_with_luks.
  def ensure_luks_open(dev_path, vg, lv)
    mapper = luks_mapper_name(vg, lv)
    return if ::File.exist?("/dev/mapper/#{mapper}")

    converge_by("Encrypt #{dev_path} with LUKS#{new_resource.luks_version}") do
      fmt = "cryptsetup --batch-mode luksFormat --type luks#{new_resource.luks_version} #{dev_path}"
      fmt += " --key-file #{new_resource.password}" if new_resource.password
      opn = "cryptsetup open #{dev_path} #{mapper} --type luks"
      opn += " --key-file #{new_resource.password}" if new_resource.password
      shell_out!(fmt)
      shell_out!(opn)
    end
  end

  # Create a filesystem on *dev* unless one already exists.
  # Uses blkid to detect existing signatures — safe for idempotency.
  def create_filesystem(fs_type, dev, fs_params = nil)
    return if fs_type.nil?
    return unless shell_out("blkid #{dev}").stdout.exclude?('TYPE=')

    converge_by("Create #{fs_type} filesystem on #{dev}") do
      cmd = "mkfs -t #{fs_type}"
      cmd += " #{fs_params}" if fs_params
      cmd += " #{dev}"
      lvm_command(cmd)
    end
  end

  # Grow a filesystem on an already-extended logical volume.
  #
  #   ext2/3/4 — resize2fs <device>        (online, device path)
  #   xfs      — xfs_growfs <mount_point>  (online, mount point REQUIRED)
  #   btrfs    — btrfs filesystem resize max <mount_point>
  #              (fsadm/lvresize -r do NOT support btrfs; always use this)
  #
  # mount_point_path is required for xfs and btrfs; ignored for ext*.
  def grow_filesystem(fs_type, dev, mount_point_path = nil)
    return if fs_type.nil?

    converge_by("Grow #{fs_type} filesystem on #{dev}") do
      case fs_type
      when 'ext2', 'ext3', 'ext4'
        lvm_command("resize2fs #{dev}")
      when 'xfs'
        mp = mount_point_path || detect_mount_point(dev)
        raise "xfs_growfs requires a mounted filesystem — cannot detect mount point for #{dev}" if mp.nil?

        lvm_command("xfs_growfs #{mp}")
      when 'btrfs'
        mp = mount_point_path || detect_mount_point(dev)
        raise "btrfs resize requires a mounted filesystem — cannot detect mount point for #{dev}" if mp.nil?

        lvm_command("btrfs filesystem resize max #{mp}")
      else
        Chef::Log.warn("lvm: no auto-grow support for filesystem '#{fs_type}' on #{dev} — resize manually")
      end
    end
  end

  # Find where *dev* is currently mounted by parsing /proc/mounts.
  # Returns the mount point String, or nil if not mounted.
  def detect_mount_point(dev)
    ::File.readlines('/proc/mounts').each do |line|
      parts = line.split
      # Match both /dev/VG/LV and /dev/mapper/VG-LV forms
      return parts[1] if parts.first == dev || ::File.realpath(parts.first) == ::File.realpath(dev)
    end
    nil
  rescue Errno::ENOENT, ArgumentError
    nil
  end

  # Declare the directory + mount Chef resources for a logical volume.
  # mp_spec is either a String (path) or a Hash with :location, :fstype,
  # :options, :dump, :pass, :device_type keys.
  def setup_mount_point(mp_spec, dev, default_fstype)
    return if mp_spec.nil?

    if mp_spec.is_a?(String)
      mp_path   = mp_spec
      mp_fstype = default_fstype
      mp_opts   = 'defaults'
      mp_dump   = 0
      mp_pass   = 2
      mp_dtype  = nil
    else
      mp_path   = mp_spec[:location]    || mp_spec['location']
      mp_fstype = mp_spec[:fstype]      || mp_spec['fstype']      || default_fstype
      mp_opts   = mp_spec[:options]     || mp_spec['options']     || 'defaults'
      mp_dump   = mp_spec[:dump]        || mp_spec['dump']        || 0
      mp_pass   = mp_spec[:pass]        || mp_spec['pass']        || 2
      mp_dtype  = mp_spec[:device_type] || mp_spec['device_type']
    end

    raise 'mount_point :location is required (got nil)' if mp_path.nil?

    directory mp_path do
      mode      '0755'
      owner     'root'
      group     'root'
      recursive true
      action    :create
    end

    mount mp_path do
      device      dev
      device_type mp_dtype if mp_dtype
      fstype      mp_fstype
      options     mp_opts
      dump        mp_dump
      pass        mp_pass
      action      %i(mount enable)
    end
  end

  # Validate that any specified physical_volumes exist in the given VG.
  def validate_pvs_in_vg!(pvs, vg_name)
    return if pvs.nil? || pvs.empty?

    pvs_in_vg = current_pvs.select { |_k, v| v['vg_name'] == vg_name }.keys
    pvs.each do |pv|
      raise "Physical volume '#{pv}' is not in volume group '#{vg_name}'!" \
        unless pvs_in_vg.include?(pv)
    end
  end
end
