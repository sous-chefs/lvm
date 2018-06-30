require 'spec_helper'

describe 'test::create' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: platform, version: version).converge('test::create')
  end

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:shell_out).and_call_original
    pvs = double('pvs', stdout: '1')
    allow_any_instance_of(Chef::Recipe).to receive(:shell_out).with('pvs | grep -c /dev/loop1').and_return(pvs)
    allow(File).to receive(:stat).and_call_original
    allow(File).to receive(:stat).with('/mnt/small').and_return(0100555)
  end

  context 'on Ubuntu 16.04' do
    let(:platform) { 'ubuntu' }
    let(:version) { '16.04' }

    it 'Create volume group' do
      expect(chef_run).to create_lvm_volume_group('vg-test')
    end

    it 'Extend volume group' do
      expect(chef_run).to extend_lvm_volume_group('vg-test')
    end

    it 'Create physical volume' do
      expect(chef_run).to create_lvm_physical_volume('/dev/loop0')
    end
  end

  context 'on RHEL 7' do
    let(:platform) { 'centos' }
    let(:version) { '7.3.1611' }

    before(:each) do
      stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
    end

    it 'Create volume group' do
      expect(chef_run).to create_lvm_volume_group('vg-test')
    end

    it 'Extend volume group' do
      expect(chef_run).to extend_lvm_volume_group('vg-test')
    end

    it 'Create physical volume' do
      expect(chef_run).to create_lvm_physical_volume('/dev/loop0')
    end
  end

  context 'on Amazon Linux' do
    let(:platform) { 'amazon' }
    let(:version) { '2016.03' }

    before(:each) do
      stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
    end

    it 'Create volume group' do
      expect(chef_run).to create_lvm_volume_group('vg-test')
    end

    it 'Extend volume group' do
      expect(chef_run).to extend_lvm_volume_group('vg-test')
    end

    it 'Create physical volume' do
      expect(chef_run).to create_lvm_physical_volume('/dev/loop0')
    end
  end
end
