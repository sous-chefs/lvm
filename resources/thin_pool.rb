# frozen_string_literal: true

provides :lvm_thin_pool
unified_mode true

default_action :create

use '_partial/_base_logical_volume'

property :physical_volumes,
          [String, Array],
          description: 'Physical volumes to use for creation'

property :stripes,
          Integer,
          callbacks: {
            'must be greater than 0' => proc { |value| value > 0 },
          },
          description: 'Number of stripes for the volume'

property :stripe_size,
          Integer,
          callbacks: {
            'must be a power of 2' => proc { |value| (Math.log2(value) % 1) == 0 },
          },
          description: 'Stripe size'

property :mirrors,
          Integer,
          callbacks: {
            'must be greater than 0' => proc { |value| value > 0 },
          },
          description: 'Number of mirrors for the volume'

property :contiguous,
          [true, false],
          description: 'Whether to use contiguous allocation policy'

property :readahead,
          [Integer, String],
          equal_to: [2..120, 'auto', 'none'].flatten!,
          description: 'Read ahead sector count of the logical volume'

property :take_up_free_space,
          [true, false],
          description: 'Whether the LV should take up the remainder of free space on the VG'

property :wipe_signatures,
          [true, false],
          default: false,
          description: 'Whether to automatically wipe any preexisting signatures'

# Thin volumes to be created in the thin pool
attr_reader :thin_volumes

def after_created
  @thin_volumes ||= []
  super
end

# A shortcut for creating a thin volume when creating the thin pool
def thin_volume(name, &block)
  @thin_volumes ||= []
  volume = declare_resource(:lvm_thin_volume, name, created_at: caller.first, &block)
  volume.action :nothing
  @thin_volumes << volume
  volume
end

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
  # Create the logical volume (thin pool)
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

  # Process thin volumes
  process_thin_volumes(:create)
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
  pe_free = lvm.volume_groups[group].free_count.to_i
  pe_count = lvm.volume_groups[group].extent_count.to_i
  lv_size_cur = lv.size.to_i / pe_size

  lv_size = new_resource.size
  lv_size = '100%FREE' if new_resource.respond_to?(:take_up_free_space) && new_resource.take_up_free_space

  resize_type = case lv_size
                when /^\d+[kKmMgGtT]$/
                  'byte'
                when /^(\d{1,2}|100)%(FREE|VG|PVS)$/
                  'percent'
                when /^(\d+)$/
                  'extent'
                end

  if resize_type == 'byte' || resize_type == 'extent'
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
                    raise("Invalid size #{Regexp.last_match[1]} for lvm resize")
                  end
  elsif resize_type == 'percent'
    percent, type = lv_size.scan(/(\d{1,2}|100)%(FREE|VG|PVS)/).first

    lv_size_req = case type
                  when 'VG'
                    ((percent.to_f / 100) * pe_count).to_i
                  when 'FREE'
                    raise('Cannot percentage based off free space') unless new_resource.take_up_free_space
                    (((percent.to_f / 100) * pe_free) + lv_size_cur).to_i
                  else
                    raise("Invalid type #{type} for resize.")
                  end
  else
    raise("Invalid size specification #{lv_size}")
  end

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

  # Process thin volumes
  process_thin_volumes(:resize)
end

action_class do
  include LVMCookbook

  def lvm_options
    new_resource.ignore_skipped_cluster ? { additional_arguments: '--ignoreskippedcluster' } : {}
  end

  def thin_volume?
    false
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
    size =
      case new_resource.size
      when /\d+[kKmMgGtT]/
        "--size #{new_resource.size}"
      when /(\d{1,2}|100)%(FREE|VG|PVS)/
        "--extents #{new_resource.size}"
      when /(\d+)/
        "--extents #{$1}" # rubocop:disable Style/PerlBackrefs
      end

    stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
    stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
    mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''
    contiguous = new_resource.contiguous ? '--contiguous y' : ''
    readahead = new_resource.readahead ? "--readahead #{new_resource.readahead}" : ''
    yes_flag = new_resource.wipe_signatures == true ? '--yes' : '-qq'
    lv_params = new_resource.lv_params
    name = new_resource.name
    group = new_resource.group
    physical_volumes = [new_resource.physical_volumes].flatten.join ' ' if new_resource.physical_volumes

    # thin pool uses --thinpool instead of --name
    "lvcreate #{size} #{stripes} #{stripe_size} #{mirrors} #{contiguous} #{readahead} #{lv_params} --thinpool #{name} #{group} #{physical_volumes} #{yes_flag}"
  end

  def resize_command(lv_size_req)
    name = new_resource.name
    group = new_resource.group
    device_name = "/dev/mapper/#{to_dm_name(group)}-#{to_dm_name(name)}"
    resize_fs =
      case new_resource.filesystem
      when /raw/i
        ''
      else
        '--resizefs'
      end
    stripes = new_resource.stripes ? "--stripes #{new_resource.stripes}" : ''
    stripe_size = new_resource.stripe_size ? "--stripesize #{new_resource.stripe_size}" : ''
    mirrors = new_resource.mirrors ? "--mirrors #{new_resource.mirrors}" : ''
    lv_params = new_resource.lv_params

    "lvextend -l #{lv_size_req} #{resize_fs} #{stripes} #{stripe_size} #{mirrors} #{device_name} #{lv_params}"
  end

  def to_dm_name(name)
    name.gsub('-', '--')
  end

  def device_formatted?(device_name, fs_type)
    Chef::Log.debug "Checking to see if #{device_name} is formatted..."
    blkid = shell_out("blkid #{device_name}")
    blkid.exitstatus == 0 && blkid.stdout.strip.include?(fs_type.strip)
  end

  def process_thin_volumes(action)
    updates = []
    new_resource.thin_volumes&.each do |tv|
      tv.group new_resource.group
      tv.pool new_resource.name
      tv.run_action action
      updates << tv.updated?
    end
    new_resource.updated_by_last_action(updates.any?)
  end
end
