require 'spec_helper'

describe 'test::test_notify' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'centos', version: '7.3.1611').converge(described_recipe)
  end

  it 'should allow resource notifications in chefspec' do
    vg_resource = chef_run.lvm_volume_group('notify_vg')
    lv_resource = chef_run.lvm_logical_volume('test_notify_lv')
    pv_resource = chef_run.lvm_physical_volume('/dev/test_notify_pv')
    [vg_resource, lv_resource, pv_resource].each do |resource|
      expect(resource).to notify('file[/tmp/test_notify]').to(:create).immediately
    end
  end
end
