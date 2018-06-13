require 'spec_helper'

describe 'test::create_thin' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: platform, version: version).converge('test::create_thin')
  end

  before do
    pvs = double('pvs', stdout: '1')
    allow_any_instance_of(Chef::Recipe).to receive(:shell_out).with('pvs | grep -c /dev/loop1').and_return(pvs)
    allow(File).to receive(:stat).and_call_original
    allow(File).to receive(:stat).with('/mnt/small').and_return(0o100555)
  end

  context 'on Ubuntu 16.04' do
    let(:platform) { 'ubuntu' }
    let(:version) { '16.04' }

    it 'Create volume group' do
      expect(chef_run).to create_lvm_volume_group('vg-data')
    end

    it 'Create thin pool' do
      expect(chef_run).to create_lvm_thin_pool('lv-thin')
    end

    it 'Create thin volume' do
      expect(chef_run).to create_lvm_thin_volume('thin_vol_1')
    end
  end

  context 'on RHEL 7' do
    let(:platform) { 'centos' }
    let(:version) { '7.3.1611' }

    before(:each) do
      stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
    end

    it 'Create volume group' do
      expect(chef_run).to create_lvm_volume_group('vg-data')
    end

    it 'Create thin pool' do
      expect(chef_run).to create_lvm_thin_pool('lv-thin')
    end

    it 'Create thin volume' do
      expect(chef_run).to create_lvm_thin_volume('thin_vol_1')
    end
  end

  context 'on Amazon Linux' do
    let(:platform) { 'amazon' }
    let(:version) { '2016.03' }

    before(:each) do
      stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
    end

    it 'Create volume group' do
      expect(chef_run).to create_lvm_volume_group('vg-data')
    end

    it 'Create thin pool' do
      expect(chef_run).to create_lvm_thin_pool('lv-thin')
    end

    it 'Create thin volume' do
      expect(chef_run).to create_lvm_thin_volume('thin_vol_1')
    end
  end
end
