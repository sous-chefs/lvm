require 'spec_helper'

describe 'test::resize' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: platform, version: version).converge('test::resize')
  end

  context 'on Ubuntu 16.04' do
    let(:platform) { 'ubuntu' }
    let(:version) { '16.04' }

    it 'Resize physical volume' do
      expect(chef_run).to resize_lvm_physical_volume('/dev/loop0')
    end

    it 'Create logical volume' do
      expect(chef_run).to create_lvm_logical_volume('small_resize')
    end

    it 'Resize logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('small_resize')
    end

    it 'Create RAW logical volume' do
      expect(chef_run).to create_lvm_logical_volume('small_resize_raw')
    end

    it 'Resize RAW logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('small_resize_raw')
    end
  end

  context 'on RHEL 7' do
    let(:platform) { 'centos' }
    let(:version) { '7.3.1611' }

    before(:each) do
      stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
    end

    it 'Resize physical volume' do
      expect(chef_run).to resize_lvm_physical_volume('/dev/loop0')
    end

    it 'Create small logical volume' do
      expect(chef_run).to create_lvm_logical_volume('small_resize')
    end

    it 'Resize logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('small_resize')
    end

    it 'Create RAW logical volume' do
      expect(chef_run).to create_lvm_logical_volume('small_resize_raw')
    end

    it 'Resize RAW logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('small_resize_raw')
    end
  end

  context 'on Amazon Linux' do
    let(:platform) { 'amazon' }
    let(:version) { '2016.03' }

    before(:each) do
      stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
    end

    it 'Resize physical volume' do
      expect(chef_run).to resize_lvm_physical_volume('/dev/loop0')
    end

    it 'Create small logical volume' do
      expect(chef_run).to create_lvm_logical_volume('small_resize')
    end

    it 'Resize logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('small_resize')
    end

    it 'Create RAW logical volume' do
      expect(chef_run).to create_lvm_logical_volume('small_resize_raw')
    end

    it 'Resize RAW logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('small_resize_raw')
    end
  end
end
