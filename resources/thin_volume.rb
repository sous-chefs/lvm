# frozen_string_literal: true

provides :lvm_thin_volume
unified_mode true

default_action :create

use '_partial/_base_logical_volume'

property :size,
          String,
          required: true,
          regex: /^(\d+[kKmMgGtT]|\d+)$/,
          description: 'Size of the thin volume'

property :pool,
          String,
          required: true,
          description: 'Name of the thin pool logical volume in which this thin volume will be created'

action :create do
  require_lvm_gems
  install_filesystem_deps

  lvm = LVM::LVM.new(lvm_options)
  name = new_resource.name
  group = new_resource.group
  fs_type = new_resource.filesystem
  fs_params = new_resource.filesystem_params
  device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
  updates = []

  vg = lvm.volume_groups[group]
  # Create the logical volume
  if vg.nil? || vg.logical_volumes.none? { |lv| lv.name == name }
    command = create_command
    Chef::Log.debug "Executing lvm command: '#{command}'"
    output = lvm.raw(command)
    Chef::Log.debug "Command output: '#{output}'"
    updates << true
  else
    lv = vg.logical_volumes.find { |v| v.name == name }
    if !lv.state.nil? && lv.state.to_sym == :active
      Chef::Log.info "Logical volume '#{name}' already exists and active. Not creating..."
    else
      Chef::Log.info "Logical volume '#{name}' already created and inactive. Activating now..."
      command = "lvchange -a y #{device_name}"
      Chef::Log.debug "Executing lvm command: '#{command}'"
      output = lvm.raw(command)
      Chef::Log.debug "Command output: '#{output}'"
      updates << true
    end
  end

  # If file system is specified, format the logical volume
  if fs_type.nil?
    Chef::Log.info 'File system type is not set. Not formatting...'
  elsif device_formatted?(device_name, fs_type)
    Chef::Log.info "Volume '#{device_name}' is already formatted. Not formatting..."
  else
    shell_out!("yes | mkfs -t #{fs_type} #{fs_params} #{device_name}")
    updates << true
  end

  # If the mount point is specified, mount the logical volume
  if new_resource.mount_point
    mount_spec = if new_resource.mount_point.is_a?(String)
                   { location: new_resource.mount_point }
                 else
                   new_resource.mount_point
                 end

    dir_resource = directory mount_spec[:location] do
      mode '755'
      owner 'root'
      group 'root'
      recursive true
      action :nothing
      not_if { Pathname.new(mount_spec[:location]).mountpoint? }
    end
    dir_resource.run_action(:create)
    updates << dir_resource.updated?

    mount_resource = mount mount_spec[:location] do
      options mount_spec[:options]
      dump mount_spec[:dump] if mount_spec[:dump]
      pass mount_spec[:pass] if mount_spec[:pass]
      device device_name
      fstype fs_type
      action :nothing
    end
    mount_resource.run_action(:mount)
    mount_resource.run_action(:enable)
    updates << mount_resource.updated?
  end
  new_resource.updated_by_last_action(updates.any?)
end

action :resize do
  require_lvm_gems
  lvm = LVM::LVM.new(lvm_options)
  name = new_resource.name
  group = new_resource.group

  vg = lvm.volume_groups[group]
  raise("Error volume group #{group} does not exist") if vg.nil?

  lv = vg.logical_volumes.select { |lvs| lvs.name == name }
  raise("Error logical volume #{name} does not exist") if lv.empty?

  lv = lv.first
  pe_size = lvm.volume_groups[group].extent_size.to_i
  lv_size_cur = lv.size.to_i / pe_size

  lv_size = new_resource.size

  lv_size_req = case lv_size
                when /^(\d+)(k|K)$/
                  (Regexp.last_match[1].to_i * 1024) / pe_size
                when /^(\d+)(m|M)$/
                  (Regexp.last_match[1].to_i * 1_048_576) / pe_size
                when /^(\d+)(g|G)$/
                  (Regexp.last_match[1].to_i * 1_073_741_824) / pe_size
                when /^(\d+)(t|T)$/
                  (Regexp.last_match[1].to_i * 1_099_511_627_776) / pe_size
                when /^(\d+)$/
                  Regexp.last_match[1].to_i
                else
                  raise("Invalid size #{lv_size} for lvm resize")
                end

  # don't resize if the current size is greater than or equal to the target size
  if lv_size_cur >= lv_size_req
    Chef::Log.debug "Logical volume #{lv.name} in volume group #{group} already at requested size"
  else
    Chef::Log.debug "Resizing logical volume #{lv.name} from #{lv_size_cur} pe to #{lv_size_req} pe"

    command = resize_command(lv_size_req)
    Chef::Log.debug "Running command: #{command}"
    output = lvm.raw command
    Chef::Log.debug "Command output: #{output}"

    new_resource.updated_by_last_action true
  end
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end

  def install_filesystem_deps
    if platform_family?('suse') && /^ext/.match(new_resource.filesystem)
      Chef::Log.debug('Installing e2fsprogs to create the filesystem')
      package "e2fsprogs package for #{new_resource.name}" do
        package_name 'e2fsprogs'
      end
    else
      Chef::Log.debug('Not installing any packages to configure the filesystem')
    end
  end

  def create_command
    size = "--virtualsize #{new_resource.size}"
    lv_params = new_resource.lv_params
    name = new_resource.name
    group = new_resource.group
    pool = new_resource.pool

    "lvcreate #{size} #{lv_params} --thin --name #{name} #{group}/#{pool}"
  end

  def resize_command(lv_size_req)
    name = new_resource.name
    group = new_resource.group
    device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"

    "lvextend -l #{lv_size_req} --resizefs #{device_name}"
  end

  def to_dm_name(name)
    name.gsub('-', '--')
  end

  def device_formatted?(device_name, fs_type)
    Chef::Log.debug "Checking to see if #{device_name} is formatted..."
    blkid = shell_out("blkid #{device_name}")
    blkid.exitstatus == 0 && blkid.stdout.strip.include?(fs_type.strip)
  end
end
