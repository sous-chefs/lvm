# frozen_string_literal: true

#
# Cookbook:: lvm
# Library:: lvm
#
# Copyright:: 2009-2024, Chef Software, Inc.
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

require 'json'

# LVMCookbook provides direct LVM query helpers using --reportformat json,
# eliminating the need for the chef-ruby-lvm and chef-ruby-lvm-attrib gems.
#
# Supported LVM versions: 2.02.158+ (--reportformat json, available on
# RHEL 7+, Ubuntu 18.04+, SUSE 15+, all of which ship LVM 2.02.166+).
#
# All size values are returned as integers in bytes (--units b --nosuffix).
module LVMCookbook
  LVM_CMD = '/sbin/lvm'

  # Returns a single VG hash by name, or nil if not found.
  # Hash keys: :name, :uuid, :extent_size, :free_count, :extent_count, :size
  def lvm_volume_group(name, options = {})
    lvm_volume_groups(options).find { |vg| vg[:name] == name }
  end

  # Returns all VGs as an array of hashes.
  def lvm_volume_groups(options = {})
    data = lvm_query('vgs -o vg_name,vg_uuid,vg_extent_size,vg_free_count,vg_extent_count,vg_size', options)
    (data['vg'] || []).map do |v|
      {
        name: v['vg_name'],
        uuid: v['vg_uuid'],
        extent_size: v['vg_extent_size'].to_i,
        free_count: v['vg_free_count'].to_i,
        extent_count: v['vg_extent_count'].to_i,
        size: v['vg_size'].to_i,
      }
    end
  end

  # Returns LVs belonging to the given VG uuid.
  # Hash keys: :name, :uuid, :attr, :size, :vg_uuid, :active, :metadata_lv, :metadata_size
  def lvm_logical_volumes_for_vg(vg_uuid, options = {})
    lvm_logical_volumes(options).select { |lv| lv[:vg_uuid] == vg_uuid }
  end

  # Returns all LVs as an array of hashes.
  def lvm_logical_volumes(options = {})
    data = lvm_query('lvs -o lv_name,lv_uuid,lv_attr,lv_size,vg_uuid,lv_active,metadata_lv,lv_metadata_size', options)
    (data['lv'] || []).map do |l|
      {
        name: l['lv_name'],
        uuid: l['lv_uuid'],
        attr: l['lv_attr'],
        size: l['lv_size'].to_i,
        vg_uuid: l['vg_uuid'],
        active: l['lv_active'],
        metadata_lv: l['metadata_lv'],
        metadata_size: l['lv_metadata_size'].to_i,
      }
    end
  end

  # Returns a single PV hash by device name, or nil if not found.
  # Hash keys: :name, :uuid, :vg_uuid, :size, :dev_size, :pe_count
  def lvm_physical_volume(name, options = {})
    lvm_physical_volumes(options).find { |pv| pv[:name] == name }
  end

  # Returns all PVs as an array of hashes.
  def lvm_physical_volumes(options = {})
    data = lvm_query('pvs -o pv_name,pv_uuid,vg_uuid,pv_size,dev_size,pv_pe_count', options)
    (data['pv'] || []).map do |p|
      {
        name: p['pv_name'],
        uuid: p['pv_uuid'],
        vg_uuid: p['vg_uuid'],
        size: p['pv_size'].to_i,
        dev_size: p['dev_size'].to_i,
        pe_count: p['pv_pe_count'].to_i,
      }
    end
  end

  # Execute a raw LVM subcommand (e.g. "vgcreate myvg /dev/sdb").
  # Prepends /sbin/lvm and appends any additional_arguments from options.
  def lvm_raw(args, options = {})
    extra = options[:additional_arguments] ? " #{options[:additional_arguments]}" : ''
    cmd = "#{LVM_CMD} #{args}#{extra}"
    Chef::Log.debug "Executing lvm command: '#{cmd}'"
    result = shell_out!(cmd)
    Chef::Log.debug "Command output: '#{result.stdout}'"
    result.stdout
  end

  # Default lvm_options — resources that support ignore_skipped_cluster override this.
  def lvm_options
    {}
  end

  # Returns true if this resource is a thin volume (skips capacity guard on resize).
  def thin_volume?
    false
  end

  # ── Utility helpers ──────────────────────────────────────────────────────

  # Converts a VG or LV name to device-mapper format (hyphens are doubled).
  def to_dm_name(name)
    name.gsub('-', '--')
  end

  # Returns true if the block device already carries the given filesystem type.
  def device_formatted?(device_name, fs_type)
    blkid = shell_out("blkid #{device_name}")
    blkid.exitstatus == 0 && blkid.stdout.strip.include?(fs_type.strip)
  end

  # Returns the mount point for a block device, or nil if not mounted.
  def get_mount_point(device)
    shell_out!('mount').stdout.each_line do |line|
      m = line.match(/#{Regexp.escape(device)}\s+on\s+(.*)\s+type.*/)
      return m[1] unless m.nil?
    end
    nil
  end

  # Install e2fsprogs on SUSE when creating an ext filesystem.
  def install_lv_filesystem_deps
    return unless platform_family?('suse') && /^ext/.match?(new_resource.filesystem.to_s)

    package 'e2fsprogs'
  end

  # Convert a requested size string to a number of physical extents.
  # Supports byte units (k/m/g/t), %VG, %FREE (requires take_up_free_space), and raw extents.
  def calculate_lv_extents(vg, lv)
    pe_size     = vg[:extent_size]
    pe_free     = vg[:free_count]
    pe_count    = vg[:extent_count]
    lv_size_cur = lv[:size] / pe_size

    lv_size = new_resource.size
    lv_size = '100%FREE' if new_resource.respond_to?(:take_up_free_space) && new_resource.take_up_free_space

    resize_type = case lv_size
                  when /^\d+[kKmMgGtT]$/ then 'byte'
                  when /^(\d{1,2}|100)%(FREE|VG|PVS)$/ then 'percent'
                  when /^\d+$/                         then 'extent'
                  end

    case resize_type
    when 'byte', 'extent'
      case lv_size
      when /^(\d+)(k|K)$/ then (Regexp.last_match(1).to_i * 1_024) / pe_size
      when /^(\d+)(m|M)$/ then (Regexp.last_match(1).to_i * 1_048_576) / pe_size
      when /^(\d+)(g|G)$/ then (Regexp.last_match(1).to_i * 1_073_741_824) / pe_size
      when /^(\d+)(t|T)$/ then (Regexp.last_match(1).to_i * 1_099_511_627_776) / pe_size
      when /^(\d+)$/ then Regexp.last_match(1).to_i
      else raise "Invalid size '#{lv_size}'"
      end
    when 'percent'
      percent, type = lv_size.scan(/(\d{1,2}|100)%(FREE|VG|PVS)/).first
      case type
      when 'VG'
        ((percent.to_f / 100) * pe_count).to_i
      when 'FREE'
        unless new_resource.respond_to?(:take_up_free_space) && new_resource.take_up_free_space
          raise 'Cannot calculate %FREE without take_up_free_space'
        end

        (((percent.to_f / 100) * pe_free) + lv_size_cur).to_i
      else
        raise "Invalid resize type '#{type}'. Use an explicit size, %VG, or take_up_free_space"
      end
    else
      raise "Invalid size specification '#{lv_size}'"
    end
  end

  # ── Shared LV action implementations ─────────────────────────────────────
  # Called from action blocks of logical_volume.rb and thin_pool.rb.
  # Each resource's action_class must define create_command, resize_command(n),
  # and remove_command to customise lvcreate/lvextend/lvremove arguments.

  # Shared :create — creates the LV, formats it, and mounts it.
  def lv_create_action(create_cmd)
    name        = new_resource.name
    group       = new_resource.group
    fs_type     = new_resource.respond_to?(:filesystem) ? new_resource.filesystem : nil
    fs_params   = (new_resource.respond_to?(:filesystem_params) ? new_resource.filesystem_params : nil).to_s
    device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"

    install_lv_filesystem_deps

    vg = lvm_volume_group(group, lvm_options)

    if vg.nil?
      converge_by("creating logical volume '#{name}' in '#{group}'") { lvm_raw(create_cmd) }
    else
      lvs = lvm_logical_volumes_for_vg(vg[:uuid], lvm_options)
      lv  = lvs.find { |l| l[:name] == name }

      if lv.nil?
        converge_by("creating logical volume '#{name}' in '#{group}'") { lvm_raw(create_cmd) }
      elsif lv[:active] == 'active'
        Chef::Log.info "Logical volume '#{name}' already exists and active. Not creating..."
      else
        converge_by("activating logical volume '#{name}'") { lvm_raw("lvchange -a y #{device_name}") }
      end
    end

    return if fs_type.nil?
    return if device_formatted?(device_name, fs_type)

    converge_by("formatting '#{device_name}' as #{fs_type}") do
      shell_out!("yes | mkfs -t #{fs_type} #{fs_params} #{device_name}")
    end

    return unless new_resource.respond_to?(:mount_point) && new_resource.mount_point

    mount_spec = new_resource.mount_point.is_a?(String) ? { location: new_resource.mount_point } : new_resource.mount_point

    directory mount_spec[:location] do
      mode '0755'
      owner 'root'
      group 'root'
      recursive true
      not_if { Pathname.new(mount_spec[:location]).mountpoint? }
      action :create
    end

    mount mount_spec[:location] do
      options mount_spec[:options]
      dump mount_spec[:dump] if mount_spec[:dump]
      pass mount_spec[:pass] if mount_spec[:pass]
      device device_name
      fstype fs_type
      action [:mount, :enable]
    end
  end

  # Shared :resize — validates capacity and extends the LV.
  def lv_resize_action
    name  = new_resource.name
    group = new_resource.group

    vg = lvm_volume_group(group, lvm_options)
    raise "Error: volume group '#{group}' does not exist" if vg.nil?

    lvs = lvm_logical_volumes_for_vg(vg[:uuid], lvm_options)
    lv  = lvs.find { |l| l[:name] == name }
    raise "Error: logical volume '#{name}' does not exist in '#{group}'" if lv.nil?

    lv_size_req = calculate_lv_extents(vg, lv)
    lv_size_cur = lv[:size] / vg[:extent_size]
    pe_free     = vg[:free_count]

    unless thin_volume? || (lv_size_req - lv_size_cur) <= pe_free
      raise "Error: cannot extend '#{name}' beyond capacity of '#{group}'"
    end

    if lv_size_cur >= lv_size_req
      Chef::Log.debug "Logical volume '#{name}' in '#{group}' already at requested size"
    else
      Chef::Log.debug "Resizing '#{name}' from #{lv_size_cur} PE to #{lv_size_req} PE (#{pe_free} PE free)"
      converge_by("resizing logical volume '#{name}' to #{lv_size_req} PE") { lvm_raw(resize_command(lv_size_req)) }
    end
  end

  # Shared :remove — unmounts and removes the LV.
  def lv_remove_action
    name        = new_resource.name
    group       = new_resource.group
    device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"

    install_lv_filesystem_deps

    if new_resource.respond_to?(:mount_point) && new_resource.mount_point
      mount_spec = new_resource.mount_point.is_a?(String) ? { location: new_resource.mount_point } : new_resource.mount_point

      mount mount_spec[:location] do
        options mount_spec[:options]
        dump mount_spec[:dump] if mount_spec[:dump]
        pass mount_spec[:pass] if mount_spec[:pass]
        device device_name
        action [:umount, :disable]
      end

      if new_resource.respond_to?(:remove_mount_point) && new_resource.remove_mount_point
        directory mount_spec[:location] do
          recursive true
          action :delete
          not_if { Pathname.new(mount_spec[:location]).mountpoint? }
        end
      end
    end

    vg = lvm_volume_group(group, lvm_options)
    if vg.nil?
      Chef::Log.info "Volume group '#{group}' not found. Not removing logical volume '#{name}'..."
      return
    end

    lvs = lvm_logical_volumes_for_vg(vg[:uuid], lvm_options)
    if lvs.any? { |lv| lv[:name] == name }
      converge_by("removing logical volume '#{name}' from '#{group}'") { lvm_raw(remove_command) }
    else
      Chef::Log.info "Logical volume '#{name}' not found in '#{group}'. Not removing..."
    end
  end

  private

  # Runs an lvm reporting subcommand with JSON output and returns the first
  # report object (a hash keyed by object type, e.g. 'vg', 'lv', 'pv').
  def lvm_query(subcmd, options = {})
    extra = options[:additional_arguments] ? " #{options[:additional_arguments]}" : ''
    cmd = "#{LVM_CMD} #{subcmd} --reportformat json --units b --nosuffix#{extra}"
    result = shell_out!(cmd)
    JSON.parse(result.stdout)['report'][0]
  end
end
