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
  install_filesystem_deps

  name = new_resource.lv_name
  group = new_resource.group
  fs_type = new_resource.filesystem
  fs_params = new_resource.filesystem_params
  device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
  updates = []

  lv = find_lv(name, group)

  # Create the logical volume
  if lv.nil?
    command = create_command
    lvm_raw(command)
    updates << true
  else
    lv_attr = lv['lv_attr'] || ''
    if lv_attr[4] == 'a'
      Chef::Log.info "Logical volume '#{name}' already exists and active. Not creating..."
    else
      Chef::Log.info "Logical volume '#{name}' already created and inactive. Activating now..."
      lvm_raw("lvchange -a y #{device_name}")
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
    mount_spec = normalized_mount_spec(new_resource.mount_point)

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
      dump mount_spec[:dump]
      pass mount_spec[:pass]
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
  name = new_resource.lv_name
  group = new_resource.group

  ext_info = vg_extent_info(group)
  pe_size = ext_info[:extent_size]

  lv = find_lv(name, group)
  raise "Logical volume '#{name}' does not exist in volume group '#{group}'" if lv.nil?

  lv_size_cur = lv['lv_size'].to_i / pe_size

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
    Chef::Log.debug "Logical volume #{name} in volume group #{group} already at requested size"
  else
    Chef::Log.debug "Resizing logical volume #{name} from #{lv_size_cur} pe to #{lv_size_req} pe"

    command = resize_command(lv_size_req)
    lvm_raw(command)

    new_resource.updated_by_last_action true
  end
end

action_class do
  include LVMCookbook

  def install_filesystem_deps
    if platform_family?('suse') && /^ext/.match(new_resource.filesystem)
      Chef::Log.debug('Installing e2fsprogs to create the filesystem')
      package "e2fsprogs package for #{new_resource.lv_name}" do
        package_name 'e2fsprogs'
      end
    else
      Chef::Log.debug('Not installing any packages to configure the filesystem')
    end
  end

  def create_command
    size = "--virtualsize #{new_resource.size}"
    lv_params = new_resource.lv_params
    name = new_resource.lv_name
    group = new_resource.group
    pool = new_resource.pool

    "lvcreate #{size} #{lv_params} --thin --name #{name} #{group}/#{pool}"
  end

  def resize_command(lv_size_req)
    name = new_resource.lv_name
    group = new_resource.group
    device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"

    "lvextend -l #{lv_size_req} --resizefs #{device_name}"
  end
end
