# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lvm_thin_volume' do
  let(:vg_name)   { 'datavg' }
  let(:pool_name) { 'thinpool' }
  let(:lv_name)   { 'thinlv' }
  let(:lv_key)    { "#{vg_name}/#{lv_name}" }
  let(:pool_key)  { "#{vg_name}/#{pool_name}" }
  let(:dev_path)  { "/dev/#{vg_name}/#{lv_name}" }

  let(:existing_vgs) do
    { vg_name => { 'vg_name' => vg_name, 'vg_extent_size' => '4194304',
                   'vg_free_count' => '2560' } }
  end

  let(:existing_pool) do
    { pool_key => { 'lv_name' => pool_name, 'vg_name' => vg_name,
                    'lv_attr' => 'twi-a-tz--', 'lv_size' => '10737418240' } }
  end

  before do
    allow(LvmHelper).to receive(:pvs).and_return({})
    allow(LvmHelper).to receive(:vgs).and_return(existing_vgs)
    allow(LvmHelper).to receive(:lvs).and_return(existing_pool)
  end

  context ':create — thin volume does not exist' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'runs lvcreate --thin with --virtualsize' do
      expect(chef_run).to run_execute(%r{lvcreate.*--thin.*--virtualsize.*#{vg_name}/#{pool_name}})
    end

    it 'does not try to create a filesystem if none specified' do
      expect(chef_run).not_to run_execute(/mkfs/)
    end
  end

  context ':create — thin volume already exists' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return(
        existing_pool.merge(
          lv_key => { 'lv_name' => lv_name, 'vg_name' => vg_name,
                      'lv_attr' => 'Vwi-a-tz--', 'lv_size' => '53687091200' }
        )
      )
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'does not run lvcreate' do
      expect(chef_run).not_to run_execute(/lvcreate/)
    end
  end

  context ':create — with xfs filesystem and mount point' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    let(:dummy_blkid) { double('blkid', stdout: '', stderr: '', exitstatus: 1) }

    before do
      allow_any_instance_of(Chef::Provider).to receive(:shell_out)
        .with(/blkid/).and_return(dummy_blkid)
    end

    it 'creates an xfs filesystem' do
      expect(chef_run).to run_execute(/mkfs.*-t xfs/)
    end

    it 'mounts the volume at the given path' do
      expect(chef_run).to mount_mount('/data')
    end

    it 'enables the mount in fstab' do
      expect(chef_run).to enable_mount('/data')
    end
  end

  context ':create — pool does not exist' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return({})
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'raises an error about the missing pool' do
      expect { chef_run }.to raise_error(/Thin pool.*does not exist/)
    end
  end

  context ':create — btrfs filesystem grow path' do
    let(:chef_run_resize) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '22.04') do |_node|
      end.converge_described_resource
    end

    it 'uses btrfs filesystem resize max (not fsadm/resize2fs)' do
      # grow_filesystem for btrfs must call btrfs, not resize2fs
      # This is a contract test on LvmActionHelpers#grow_filesystem
      helpers = Class.new { include LvmActionHelpers }.new
      allow(helpers).to receive(:shell_out!).and_call_original
      allow(helpers).to receive(:detect_mount_point).and_return('/data')
      allow(helpers).to receive(:converge_by).and_yield
      allow(helpers).to receive(:lvm_command) { |cmd| cmd }

      result = helpers.grow_filesystem('btrfs', '/dev/datavg/thinlv', '/data')
      expect(result).to match(/btrfs filesystem resize max/)
    end
  end
end
