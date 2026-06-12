# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lvm_physical_volume' do
  let(:chef_run_create) do
    ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |node|
      # stub LvmHelper at the node level
    end.converge_described_resource
  end

  before do
    allow(LvmHelper).to receive(:pvs).and_return({})
    allow(LvmHelper).to receive(:vgs).and_return({})
    allow(LvmHelper).to receive(:lvs).and_return({})
  end

  context ':create — PV does not exist' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'runs pvcreate' do
      expect(chef_run).to run_execute('pvcreate /dev/sdb').with(command: /pvcreate/)
    end
  end

  context ':create — PV already exists' do
    before do
      allow(LvmHelper).to receive(:pvs).and_return(
        '/dev/sdb' => { 'pv_name' => '/dev/sdb', 'vg_name' => '' }
      )
    end

    it 'does not run pvcreate' do
      expect(chef_run_create).not_to run_execute('pvcreate /dev/sdb')
    end
  end
end
