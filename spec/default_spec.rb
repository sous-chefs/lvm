require 'spec_helper'

describe 'lvm::default' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '12.04').converge('lvm::default')
  end

  it 'installs lvm2' do
    expect(chef_run).to install_package('lvm2')
  end
end
