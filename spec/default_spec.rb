require 'spec_helper'

describe 'lvm::default on Ubuntu 16.04' do
  cached(:chef_run_ubuntu) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04').converge('lvm::default')
  end

  it 'installs lvm2' do
    expect(chef_run_ubuntu).to install_package('lvm2')
  end

  it 'does not start or enable lvm2-lvmetad' do
    expect(chef_run_ubuntu).to_not start_service('lvm2-lvmetad')
    expect(chef_run_ubuntu).to_not enable_service('lvm2-lvmetad')
  end
end

describe 'lvm::default on RHEL 7' do
  cached(:chef_run_rhel) do
    ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611').converge('lvm::default')
  end

  before(:each) do
    stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
  end

  it 'installs lvm2' do
    expect(chef_run_rhel).to install_package('lvm2')
  end

  it 'starts / enables lvm2-lvmetad' do
    expect(chef_run_rhel).to start_service('lvm2-lvmetad')
    expect(chef_run_rhel).to enable_service('lvm2-lvmetad')
  end
end

describe 'lvm::default on Amazon Linux' do
  cached(:chef_run_amazon) do
    ChefSpec::SoloRunner.new(platform: 'amazon', version: '2016.03').converge('lvm::default')
  end

  before(:each) do
    stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
  end

  it 'installs lvm2' do
    expect(chef_run_amazon).to install_package('lvm2')
  end

  it 'does not start or enable lvm2-lvmetad' do
    expect(chef_run_amazon).to_not start_service('lvm2-lvmetad')
    expect(chef_run_amazon).to_not enable_service('lvm2-lvmetad')
  end
end
