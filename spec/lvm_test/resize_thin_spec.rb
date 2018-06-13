require 'spec_helper'

describe 'test::resize_thin' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: platform, version: version).converge('test::resize_thin')
  end

  describe 'on Ubuntu 16.04' do
    let(:platform) { 'ubuntu' }
    let(:version) { '16.04' }

    it 'resizes logical volume' do
      expect(chef_run).to resize_lvm_thin_volume('thin_vol_1')
    end
  end

  describe 'on RHEL 7' do
    let(:platform) { 'centos' }
    let(:version) { '7.3.1611' }

    it 'resizes logical volume' do
      expect(chef_run).to resize_lvm_thin_volume('thin_vol_1')
    end
  end

  describe 'on Amazon Linux' do
    let(:platform) { 'amazon' }
    let(:version) { '2016.03' }

    it 'resizes logical volume' do
      expect(chef_run).to resize_lvm_thin_volume('thin_vol_1')
    end
  end
end
