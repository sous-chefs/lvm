# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lvm_volume_group' do
  let(:existing_pvs) do
    {
      '/dev/sdb' => { 'pv_name' => '/dev/sdb', 'vg_name' => '' },
      '/dev/sdc' => { 'pv_name' => '/dev/sdc', 'vg_name' => '' },
    }
  end

  before do
    allow(LvmHelper).to receive(:pvs).and_return(existing_pvs)
    allow(LvmHelper).to receive(:vgs).and_return({})
    allow(LvmHelper).to receive(:lvs).and_return({})
  end

  context ':create — VG does not exist' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'runs vgcreate' do
      expect(chef_run).to run_execute('vgcreate datavg /dev/sdb /dev/sdc')
        .with(command: /vgcreate/)
    end
  end

  context ':create — VG already exists' do
    before do
      allow(LvmHelper).to receive(:vgs).and_return(
        'datavg' => { 'vg_name' => 'datavg', 'pv_count' => '2' }
      )
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'does not run vgcreate' do
      expect(chef_run).not_to run_execute('vgcreate datavg')
    end
  end
end
