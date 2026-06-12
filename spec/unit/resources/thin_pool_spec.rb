# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lvm_thin_pool' do
  let(:vg_name)   { 'datavg' }
  let(:pool_name) { 'thinpool' }

  before do
    allow(LvmHelper).to receive(:pvs).and_return({})
    allow(LvmHelper).to receive(:vgs).and_return(
      vg_name => { 'vg_name' => vg_name, 'vg_extent_size' => '4194304',
                   'vg_free_count' => '2560' }
    )
    allow(LvmHelper).to receive(:lvs).and_return({})
  end

  context ':create — pool does not exist' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'runs lvcreate --thin' do
      expect(chef_run).to run_execute("lvcreate --thin -L 10G -n #{pool_name} #{vg_name}")
        .with(command: /lvcreate.*--thin/)
    end
  end

  context ':create — pool already exists' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return(
        "#{vg_name}/#{pool_name}" => {
          'lv_name' => pool_name, 'vg_name' => vg_name,
          'lv_attr' => 'twi-a-tz--', 'lv_size' => '10737418240'
        }
      )
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'does not run lvcreate' do
      expect(chef_run).not_to run_execute("lvcreate --thin -L 10G -n #{pool_name} #{vg_name}")
    end
  end

  context ':create — with chunksize and zero false' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_node|
      end.converge_described_resource
    end

    it 'includes --chunksize and --zero n flags' do
      expect(chef_run).to run_execute(/--chunksize.*--zero n/)
    end
  end
end
