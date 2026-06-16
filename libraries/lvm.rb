# frozen_string_literal: true

#
# LVMCookbook - Helper module for querying LVM state using JSON output
#
# Uses LVM2's built-in --reportformat json (available since 2.02.158, 2017)
# with --units b --nosuffix to get consistent byte values for size calculations.
#
# All query methods return Ruby hashes (or nil/empty array) rather than objects,
# eliminating the need for the chef-ruby-lvm and chef-ruby-lvm-attrib gems.
#
module LVMCookbook
  require 'json'

  # Run an LVM report command and parse the JSON output.
  # Returns the parsed array of report entries for the given report key.
  #
  # @param cmd [String] the LVM command (pvs, vgs, lvs)
  # @param report_key [String] the JSON key containing results ('pv', 'vg', 'lv')
  # @param additional_args [String, nil] extra arguments (e.g. '--ignoreskippedcluster')
  # @return [Array<Hash>] parsed results
  def lvm_report(cmd, report_key, additional_args: nil)
    full_cmd = "#{cmd} --reportformat json --units b --nosuffix #{additional_args}".strip
    result = shell_out!(full_cmd, returns: [0, 5])
    data = JSON.parse(result.stdout)
    data.dig('report', 0, report_key) || []
  rescue JSON::ParserError => e
    Chef::Log.warn("Failed to parse LVM JSON output for '#{cmd}': #{e.message}")
    []
  end

  # Find a physical volume by device name.
  #
  # @param device [String] device path (e.g. '/dev/sdb')
  # @return [Hash, nil] PV info hash or nil if not found
  def find_pv(device)
    pvs = lvm_report('pvs -a -o pv_all', 'pv')
    pvs.find { |pv| pv['pv_name'] == device }
  end

  # Find a volume group by name.
  #
  # @param name [String] volume group name
  # @return [Hash, nil] VG info hash or nil if not found
  def find_vg(name)
    vgs = lvm_report('vgs -a -o vg_all', 'vg')
    vgs.find { |vg| vg['vg_name'] == name }
  end

  # Find a logical volume by name within a volume group.
  #
  # @param lv_name [String] logical volume name
  # @param vg_name [String] volume group name
  # @return [Hash, nil] LV info hash or nil if not found
  def find_lv(lv_name, vg_name)
    lvs = lvm_report("lvs -a -o lv_all #{vg_name}", 'lv')
    lvs.find { |lv| lv['lv_name'] == lv_name }
  end

  # List all logical volumes in a volume group.
  #
  # @param vg_name [String] volume group name
  # @return [Array<Hash>] array of LV info hashes
  def list_lvs(vg_name)
    lvm_report("lvs -a -o lv_all #{vg_name}", 'lv')
  end

  # Get volume group extent information needed for size calculations.
  #
  # @param vg_name [String] volume group name
  # @return [Hash] with keys :extent_size, :extent_count, :free_count (all integers, bytes for extent_size)
  def vg_extent_info(vg_name)
    vg = find_vg(vg_name)
    raise "Volume group '#{vg_name}' does not exist" if vg.nil?

    {
      extent_size: vg['vg_extent_size'].to_i,
      extent_count: vg['vg_extent_count'].to_i,
      free_count: vg['vg_free_count'].to_i,
    }
  end

  # List physical volumes that belong to a given volume group.
  #
  # @param vg_name [String] volume group name
  # @return [Array<Hash>] array of PV info hashes
  def list_pvs_in_vg(vg_name)
    pvs = lvm_report('pvs -a -o pv_all', 'pv')
    pvs.select { |pv| pv['vg_name'] == vg_name }
  end

  # Run a raw LVM command (for create/modify/delete operations).
  #
  # @param command [String] the full LVM command
  # @param args [Hash] additional shell_out options
  # @return [String] command stdout
  def lvm_raw(command, **args)
    Chef::Log.debug("Executing LVM command: '#{command}'")
    result = shell_out!(command, **args)
    Chef::Log.debug("Command output: '#{result.stdout}'")
    result.stdout
  end

  # Converts the device name to the device-mapper name format.
  # LVM uses double-hyphens to escape single hyphens in DM names.
  #
  # @param name [String] VG or LV name
  # @return [String] DM-safe name
  def to_dm_name(name)
    name.gsub('-', '--')
  end

  # Checks if a device is formatted with the given file system type.
  #
  # @param device_name [String] device path
  # @param fs_type [String] filesystem type to check for
  # @return [Boolean]
  def device_formatted?(device_name, fs_type)
    Chef::Log.debug("Checking to see if #{device_name} is formatted...")
    blkid = shell_out("blkid #{device_name}")
    blkid.exitstatus == 0 && blkid.stdout.strip.include?(fs_type.strip)
  end
end
