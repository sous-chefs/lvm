# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lvm_logical_volume' do
  let(:vg_name) { 'datavg' }
  let(:lv_name) { 'datalv' }
  let(:lv_key)  { "#{vg_name}/#{lv_name}" }

  let(:existing_vgs) do
    { vg_name => { 'vg_name' => vg_name, 'vg_extent_size' => '4194304',
                   'vg_free_count' => '2560' } }
  end

  before do
    allow(LvmHelper).to receive(:pvs).and_return({})
    allow(LvmHelper).to receive(:vgs).and_return(existing_vgs)
    allow(LvmHelper).to receive(:lvs).and_return({})
  end

  context ':create — LV does not exist' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'runs lvcreate with the right flags' do
      expect(chef_run).to run_execute(/lvcreate.*-L 10G.*-n #{lv_name}.*#{vg_name}/)
    end
  end

  context ':create — LV already exists' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return(
        lv_key => { 'lv_name' => lv_name, 'vg_name' => vg_name,
                    'lv_size' => '10737418240', 'lv_attr' => '-wi-a-----' }
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

  context ':create — with xfs filesystem (RHEL 10 default)' do
    let(:dummy_blkid) { double('blkid', stdout: '', stderr: '', exitstatus: 1) }

    before do
      allow_any_instance_of(Chef::Provider).to receive(:shell_out)
        .with(/blkid/).and_return(dummy_blkid)
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '10') do |_node|
      end.converge_described_resource
    end

    it 'creates an xfs filesystem' do
      expect(chef_run).to run_execute(/mkfs.*-t xfs/)
    end

    it 'mounts the volume' do
      expect(chef_run).to mount_mount('/data')
      expect(chef_run).to enable_mount('/data')
    end
  end

  context ':create — with ext4 filesystem (Ubuntu 26.04 default)' do
    let(:dummy_blkid) { double('blkid', stdout: '', stderr: '', exitstatus: 1) }

    before do
      allow_any_instance_of(Chef::Provider).to receive(:shell_out)
        .with(/blkid/).and_return(dummy_blkid)
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '24.04') do |_node|
      end.converge_described_resource
    end

    it 'creates an ext4 filesystem' do
      expect(chef_run).to run_execute(/mkfs.*-t ext4/)
    end
  end

  context ':resize — LV needs growing' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return(
        lv_key => { 'lv_name' => lv_name, 'vg_name' => vg_name,
                    'lv_size' => '10737418240', 'lv_attr' => '-wi-a-----' }
      )
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'runs lvresize to the new size' do
      expect(chef_run).to run_execute(/lvresize.*-L 20G/)
    end
  end

  context ':resize — xfs grow uses xfs_growfs with mount point' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return(
        lv_key => { 'lv_name' => lv_name, 'vg_name' => vg_name,
                    'lv_size' => '10737418240', 'lv_attr' => '-wi-a-----' }
      )
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '10') do |_node|
      end.converge_described_resource
    end

    it 'calls xfs_growfs with the mount point (not the device path)' do
      expect(chef_run).to run_execute(%r{xfs_growfs /data})
    end
  end

  context ':resize — btrfs grow uses btrfs filesystem resize max' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return(
        lv_key => { 'lv_name' => lv_name, 'vg_name' => vg_name,
                    'lv_size' => '10737418240', 'lv_attr' => '-wi-a-----' }
      )
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '24.04') do |_node|
      end.converge_described_resource
    end

    it 'calls btrfs filesystem resize max — not fsadm or resize2fs' do
      expect(chef_run).to run_execute(/btrfs filesystem resize max/)
      expect(chef_run).not_to run_execute(/resize2fs/)
      expect(chef_run).not_to run_execute(/fsadm/)
    end
  end

  context 'LvmActionHelpers#grow_filesystem' do
    subject(:helpers) { Class.new { include LvmActionHelpers }.new }

    before do
      allow(helpers).to receive(:converge_by).and_yield
      allow(helpers).to receive(:lvm_command) { |cmd| cmd }
      allow(helpers).to receive(:detect_mount_point).and_return('/data')
    end

    it 'uses resize2fs for ext4' do
      result = helpers.grow_filesystem('ext4', '/dev/datavg/datalv', nil)
      expect(result).to match(/resize2fs/)
    end

    it 'uses xfs_growfs with mount point for xfs' do
      result = helpers.grow_filesystem('xfs', '/dev/datavg/datalv', '/data')
      expect(result).to match(%r{xfs_growfs /data})
    end

    it 'uses btrfs filesystem resize max with mount point for btrfs' do
      result = helpers.grow_filesystem('btrfs', '/dev/datavg/datalv', '/data')
      expect(result).to match(%r{btrfs filesystem resize max /data})
    end

    it 'logs a warning for unknown filesystem types' do
      expect(Chef::Log).to receive(:warn).with(/no auto-grow support/)
      helpers.grow_filesystem('reiserfs', '/dev/datavg/datalv', nil)
    end
  end
end
