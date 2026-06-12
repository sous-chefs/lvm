# frozen_string_literal: true
#
# Cookbook:: lvm
# Library:: lvm_helper
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
# LvmHelper
# ---------------------------------------------------------------------------
# Pure Ruby replacement for the chef-ruby-lvm + chef-ruby-lvm-attrib gems.
#
# Uses `lvm <cmd> --reportformat json` (available on every distro from
# RHEL 7 / Ubuntu 18.04 onward; introduced in LVM 2.02.158, June 2016).
#
# JSON output format:
#   { "report": [ { "lv": [ { "lv_name": "...", ... }, ... ] } ] }
#
# All numeric values are returned as strings by lvm; call .to_i / .to_f as
# needed.  With --units b --nosuffix sizes are always whole byte counts.
#
# Public API (called from action_class helpers in each resource):
#
#   LvmHelper.pvs(shell_out_fn)    -> Hash { "/dev/sda" => { pv_name:, pv_uuid:, ... } }
#   LvmHelper.vgs(shell_out_fn)    -> Hash { "myvg"     => { vg_name:, vg_uuid:, ... } }
#   LvmHelper.lvs(shell_out_fn)    -> Hash { "myvg/mylv"=> { lv_name:, vg_name:, ... } }
#
# Each hash value is a plain Ruby Hash with string keys matching lvm column
# names (lv_name, lv_uuid, lv_size, lv_attr, etc.).  Callers treat missing
# keys as absent / non-existent objects.
# ---------------------------------------------------------------------------

require 'json'

module LvmHelper
  # ---------------------------------------------------------------------------
  # Column lists — minimal set needed by cookbook providers.
  # Stable on every version from LVM 2.02.176 (RHEL7/Ubuntu18.04) onward.
  # ---------------------------------------------------------------------------

  PV_COLUMNS = %w(
    pv_name pv_uuid pv_size pv_free pv_used pv_attr
    pe_start pv_pe_count pv_pe_alloc_count dev_size
    vg_name vg_uuid
  ).freeze

  VG_COLUMNS = %w(
    vg_name vg_uuid vg_size vg_free
    vg_extent_size vg_extent_count vg_free_count
    vg_attr pv_count lv_count
  ).freeze

  LV_COLUMNS = %w(
    lv_name lv_uuid lv_size lv_attr lv_path lv_full_name lv_layout
    lv_role lv_parent
    data_percent metadata_percent pool_lv pool_lv_uuid
    origin origin_uuid copy_percent sync_percent
    lv_metadata_size seg_count
    data_lv metadata_lv
    vg_name vg_uuid
  ).freeze

  # ---------------------------------------------------------------------------
  # Public query methods
  # ---------------------------------------------------------------------------

  # Returns a Hash keyed by pv_name ("/dev/sda")
  def self.pvs(shell_out_fn)
    rows = lvm_report('pvs', 'pv', PV_COLUMNS, shell_out_fn)
    rows.each_with_object({}) { |row, h| h[row['pv_name']] = row }
  end

  # Returns a Hash keyed by vg_name ("datavg")
  def self.vgs(shell_out_fn)
    rows = lvm_report('vgs', 'vg', VG_COLUMNS, shell_out_fn)
    rows.each_with_object({}) { |row, h| h[row['vg_name']] = row }
  end

  # Returns a Hash keyed by "vg_name/lv_name" ("datavg/datalv")
  def self.lvs(shell_out_fn)
    rows = lvm_report('lvs', 'lv', LV_COLUMNS, shell_out_fn)
    rows.each_with_object({}) do |row, h|
      key = "#{row['vg_name']}/#{row['lv_name']}"
      h[key] = row
    end
  end

  # ---------------------------------------------------------------------------
  # Size conversion utilities (used for pre-flight validation)
  # ---------------------------------------------------------------------------

  # Convert a human size string ("10G", "512M", "1T") to bytes (Integer).
  # Returns nil if the string does not look like an absolute size.
  def self.size_to_bytes(size)
    return unless size.is_a?(String)
    case size
    when /\A(\d+(?:\.\d+)?)\s*[Bb]\z/       then Regexp.last_match(1).to_f.to_i
    when /\A(\d+(?:\.\d+)?)\s*[Kk][Bb]?\z/  then (Regexp.last_match(1).to_f * 1_024).to_i
    when /\A(\d+(?:\.\d+)?)\s*[Mm][Bb]?\z/  then (Regexp.last_match(1).to_f * 1_024**2).to_i
    when /\A(\d+(?:\.\d+)?)\s*[Gg][Bb]?\z/  then (Regexp.last_match(1).to_f * 1_024**3).to_i
    when /\A(\d+(?:\.\d+)?)\s*[Tt][Bb]?\z/  then (Regexp.last_match(1).to_f * 1_024**4).to_i
    when /\A(\d+(?:\.\d+)?)\s*[Pp][Bb]?\z/  then (Regexp.last_match(1).to_f * 1_024**5).to_i
    when /\A(\d+(?:\.\d+)?)\s*[Ee][Bb]?\z/  then (Regexp.last_match(1).to_f * 1_024**6).to_i
    end
  end

  # Returns true if size is a relative spec (%VG, %FREE, %PVS, 100%FREE, etc.)
  def self.relative_size?(size)
    size.is_a?(String) && size =~ /\d+%(?:VG|FREE|PVS|ORIGIN)/i
  end

  # ---------------------------------------------------------------------------
  # Internal helpers
  # ---------------------------------------------------------------------------

  # Run an lvm reporting command and return an Array of row Hashes.
  #
  # @param cmd       [String]   "pvs", "vgs", or "lvs"
  # @param report_key[String]   JSON key inside report[0]: "pv", "vg", or "lv"
  # @param columns   [Array]    column names to request
  # @param sof       [Proc]     callable(cmd_string) -> shell_out result
  # @return          [Array<Hash>]
  def self.lvm_report(cmd, report_key, columns, sof)
    full_cmd = "lvm #{cmd} --reportformat json --units b --nosuffix " \
               "--noheadings -o #{columns.join(',')}"
    result = sof.call(full_cmd)

    # lvm exits 5 when a VG is exported (partial run); treat same as 0
    unless [0, 5].include?(result.exitstatus)
      raise "lvm #{cmd} failed (exit #{result.exitstatus}): #{result.stderr}"
    end

    stdout = result.stdout.strip
    return [] if stdout.empty?

    begin
      parsed = JSON.parse(stdout)
    rescue JSON::ParserError => e
      raise "Failed to parse lvm #{cmd} JSON output: #{e.message}\nOutput was:\n#{stdout}"
    end

    # Structure: { "report": [ { "lv": [...] } ] }
    report_arr = parsed['report']
    return [] unless report_arr.is_a?(Array) && !report_arr.empty?

    rows = report_arr[0][report_key]
    rows.is_a?(Array) ? rows : []
  end

  private_class_method :lvm_report
end
