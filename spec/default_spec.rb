require 'spec_helper'

describe 'lvm::default on Ubuntu 14.04' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '14.04').converge('lvm::default')
  end

  it 'installs lvm2' do
    expect(chef_run).to install_package('lvm2')
  end
end

describe 'lvm::default on RHEL 7' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'centos', version: '7.0').converge('lvm::default')
  end

  before(:each) do
    stub_command('/sbin/lvm dumpconfig global/use_lvmetad | grep use_lvmetad=1').and_return(true)
  end

  it 'installs lvm2' do
    expect(chef_run).to install_package('lvm2')
  end

  it 'starts / enables lvm2-lvmetad' do
    expect(chef_run).to start_service('lvm2-lvmetad')
    expect(chef_run).to enable_service('lvm2-lvmetad')
  end
end
