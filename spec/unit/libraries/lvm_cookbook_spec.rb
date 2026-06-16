# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/lvm'

describe LVMCookbook do
  let(:helper_class) do
    Class.new do
      include LVMCookbook

      # Stub shell_out! and shell_out for testing
      attr_accessor :shell_out_result

      def shell_out!(*_args)
        shell_out_result
      end

      def shell_out(*_args)
        shell_out_result
      end
    end
  end

  let(:helper) { helper_class.new }

  describe '#lvm_report' do
    let(:json_output) do
      {
        'report' => [
          {
            'pv' => [
              { 'pv_name' => '/dev/sdb', 'vg_name' => 'vg-data', 'pv_size' => '10737418240' },
            ],
          },
        ],
      }.to_json
    end

    before do
      result = double('shell_out_result', stdout: json_output, exitstatus: 0)
      helper.shell_out_result = result
    end

    it 'parses JSON output from LVM commands' do
      pvs = helper.lvm_report('pvs -a -o pv_all', 'pv')
      expect(pvs).to be_an(Array)
      expect(pvs.first['pv_name']).to eq('/dev/sdb')
    end

    it 'returns empty array when JSON parsing fails' do
      result = double('shell_out_result', stdout: 'not json', exitstatus: 0)
      helper.shell_out_result = result
      allow(Chef::Log).to receive(:warn)
      expect(helper.lvm_report('pvs', 'pv')).to eq([])
    end
  end

  describe '#find_pv' do
    let(:json_output) do
      {
        'report' => [
          {
            'pv' => [
              { 'pv_name' => '/dev/sdb', 'vg_name' => 'vg-data', 'pv_size' => '10737418240' },
              { 'pv_name' => '/dev/sdc', 'vg_name' => 'vg-data', 'pv_size' => '10737418240' },
            ],
          },
        ],
      }.to_json
    end

    before do
      result = double('shell_out_result', stdout: json_output, exitstatus: 0)
      helper.shell_out_result = result
    end

    it 'finds a PV by device name' do
      pv = helper.find_pv('/dev/sdb')
      expect(pv).not_to be_nil
      expect(pv['pv_name']).to eq('/dev/sdb')
    end

    it 'returns nil when PV does not exist' do
      expect(helper.find_pv('/dev/sdz')).to be_nil
    end
  end

  describe '#find_vg' do
    let(:json_output) do
      {
        'report' => [
          {
            'vg' => [
              { 'vg_name' => 'vg-data', 'vg_size' => '21474836480', 'vg_extent_size' => '4194304', 'vg_extent_count' => '5119', 'vg_free_count' => '2560' },
            ],
          },
        ],
      }.to_json
    end

    before do
      result = double('shell_out_result', stdout: json_output, exitstatus: 0)
      helper.shell_out_result = result
    end

    it 'finds a VG by name' do
      vg = helper.find_vg('vg-data')
      expect(vg).not_to be_nil
      expect(vg['vg_name']).to eq('vg-data')
    end

    it 'returns nil when VG does not exist' do
      expect(helper.find_vg('vg-missing')).to be_nil
    end
  end

  describe '#find_lv' do
    let(:json_output) do
      {
        'report' => [
          {
            'lv' => [
              { 'lv_name' => 'logs', 'vg_name' => 'vg-data', 'lv_size' => '10485760', 'lv_attr' => '-wi-a-----' },
              { 'lv_name' => 'data', 'vg_name' => 'vg-data', 'lv_size' => '20971520', 'lv_attr' => '-wi-a-----' },
            ],
          },
        ],
      }.to_json
    end

    before do
      result = double('shell_out_result', stdout: json_output, exitstatus: 0)
      helper.shell_out_result = result
    end

    it 'finds an LV by name within a VG' do
      lv = helper.find_lv('logs', 'vg-data')
      expect(lv).not_to be_nil
      expect(lv['lv_name']).to eq('logs')
      expect(lv['lv_size']).to eq('10485760')
    end

    it 'returns nil when LV does not exist' do
      expect(helper.find_lv('missing', 'vg-data')).to be_nil
    end
  end

  describe '#vg_extent_info' do
    let(:json_output) do
      {
        'report' => [
          {
            'vg' => [
              { 'vg_name' => 'vg-data', 'vg_extent_size' => '4194304', 'vg_extent_count' => '5119', 'vg_free_count' => '2560' },
            ],
          },
        ],
      }.to_json
    end

    before do
      result = double('shell_out_result', stdout: json_output, exitstatus: 0)
      helper.shell_out_result = result
    end

    it 'returns extent info as a hash' do
      info = helper.vg_extent_info('vg-data')
      expect(info[:extent_size]).to eq(4_194_304)
      expect(info[:extent_count]).to eq(5119)
      expect(info[:free_count]).to eq(2560)
    end

    it 'raises when VG does not exist' do
      empty_output = { 'report' => [{ 'vg' => [] }] }.to_json
      result = double('shell_out_result', stdout: empty_output, exitstatus: 0)
      helper.shell_out_result = result
      expect { helper.vg_extent_info('missing') }.to raise_error(RuntimeError, /does not exist/)
    end
  end

  describe '#to_dm_name' do
    it 'escapes hyphens for device mapper' do
      expect(helper.to_dm_name('vg-data')).to eq('vg--data')
    end

    it 'handles names without hyphens' do
      expect(helper.to_dm_name('vgdata')).to eq('vgdata')
    end
  end

  describe '#device_formatted?' do
    it 'returns true when device has the filesystem type' do
      result = double('shell_out_result', stdout: '/dev/mapper/vg--data-logs: UUID="abc" TYPE="ext4"', exitstatus: 0)
      helper.shell_out_result = result
      allow(Chef::Log).to receive(:debug)
      expect(helper.device_formatted?('/dev/mapper/vg--data-logs', 'ext4')).to be true
    end

    it 'returns false when device is not formatted' do
      result = double('shell_out_result', stdout: '', exitstatus: 2)
      helper.shell_out_result = result
      allow(Chef::Log).to receive(:debug)
      expect(helper.device_formatted?('/dev/mapper/vg--data-logs', 'ext4')).to be false
    end
  end
end
