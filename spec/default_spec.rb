require 'spec_helper'

describe 'lvm::default' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '12.04').converge('lvm::default')
  end

  it 'installs lvm2' do
    expect(chef_run).to install_package('lvm2')
  end

  it 'installs `di-ruby-lvm-attrib` as a Ruby gem' do
    expect(chef_run).to install_chef_gem('di-ruby-lvm-attrib').with(version: '0.0.25')
  end

  it 'installs `di-ruby-lvm` as a Ruby gem' do
    expect(chef_run).to install_chef_gem('di-ruby-lvm').with(version: '0.2.1')
  end
end
