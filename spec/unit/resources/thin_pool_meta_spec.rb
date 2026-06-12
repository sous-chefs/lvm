# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lvm_thin_pool_meta' do
  let(:vg_name)   { 'datavg' }
  let(:pool_name) { 'thinpool' }
  let(:pool_key)  { "#{vg_name}/#{pool_name}" }

  # Simulate `lvs --all` output for the hidden [thinpool_tmeta] LV.
  # LVM reports the internal metadata LV with brackets in its name.
  let(:meta_lv_line) { "  [#{pool_name}_tmeta]  536870912" } # 512 MiB current

  let(:existing_vgs) do
    { vg_name => { 'vg_name' => vg_name, 'vg_extent_size' => '4194304',
                   'vg_free_count' => '2560' } }
  end

  let(:existing_pool) do
    { pool_key => { 'lv_name' => pool_name, 'vg_name' => vg_name,
                    'lv_attr' => 'twi-a-tz--', 'lv_size' => '10737418240' } }
  end

  before do
    allow(LvmHelper).to receive(:pvs).and_return({})
    allow(LvmHelper).to receive(:vgs).and_return(existing_vgs)
    allow(LvmHelper).to receive(:lvs).and_return(existing_pool)

    # Stub the `lvs --all` call used by current_meta_size_bytes
    meta_cmd = double('meta_lvs', stdout: meta_lv_line, exitstatus: 0)
    allow_any_instance_of(Chef::Provider)
      .to receive(:shell_out)
      .with(/lvs.*--all.*#{vg_name}/, anything)
      .and_return(meta_cmd)
  end

  context ':create — metadata smaller than desired size' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_n|
      end.converge_described_resource
    end

    # Current: 512 MiB; desired: 1 GiB — should extend
    it 'runs lvextend --poolmetadatasize' do
      expect(chef_run).to run_execute(%r{lvextend.*--poolmetadatasize.*1G.*#{vg_name}/#{pool_name}})
    end

    it 'sets poolmetadataspare y (persist: true default)' do
      expect(chef_run).to run_execute(/lvchange.*--poolmetadataspare y.*#{vg_name}/)
    end
  end

  context ':create — metadata already large enough' do
    let(:meta_lv_line_large) { "  [#{pool_name}_tmeta]  2147483648" } # 2 GiB current

    before do
      large_cmd = double('meta_lvs_large', stdout: meta_lv_line_large, exitstatus: 0)
      allow_any_instance_of(Chef::Provider)
        .to receive(:shell_out)
        .with(/lvs.*--all.*#{vg_name}/, anything)
        .and_return(large_cmd)
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_n|
      end.converge_described_resource
    end

    it 'does not run lvextend' do
      expect(chef_run).not_to run_execute(/lvextend/)
    end

    it 'still sets poolmetadataspare' do
      expect(chef_run).to run_execute(/lvchange.*--poolmetadataspare y/)
    end
  end

  context ':create — with persist: false' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_n|
      end.converge_described_resource
    end

    it 'sets poolmetadataspare n' do
      expect(chef_run).to run_execute(/lvchange.*--poolmetadataspare n.*#{vg_name}/)
    end
  end

  context ':create — pool does not exist' do
    before do
      allow(LvmHelper).to receive(:lvs).and_return({})
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_n|
      end.converge_described_resource
    end

    it 'raises a descriptive error' do
      expect { chef_run }.to raise_error(/Thin pool.*does not exist/)
    end
  end

  context ':create — VG does not exist' do
    before do
      allow(LvmHelper).to receive(:vgs).and_return({})
    end

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_n|
      end.converge_described_resource
    end

    it 'raises a descriptive error about the VG' do
      expect { chef_run }.to raise_error(/Volume group.*does not exist/)
    end
  end

  context ':create — with stripes and stripe_size' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'redhat', version: '8') do |_n|
      end.converge_described_resource
    end

    it 'passes --stripes and --stripesize to lvextend' do
      expect(chef_run).to run_execute(/lvextend.*--stripes 2.*--stripesize 64/)
    end
  end

  context 'LvmHelper size utilities' do
    it 'relative_size? returns true for percent specs' do
      expect(LvmHelper.relative_size?('10%VG')).to be true
      expect(LvmHelper.relative_size?('100%FREE')).to be true
    end

    it 'relative_size? returns false for absolute specs' do
      expect(LvmHelper.relative_size?('1G')).to   be false
      expect(LvmHelper.relative_size?('512M')).to be false
    end

    it 'size_to_bytes correctly converts common units' do
      expect(LvmHelper.size_to_bytes('512M')).to eq(536_870_912)
      expect(LvmHelper.size_to_bytes('1G')).to   eq(1_073_741_824)
      expect(LvmHelper.size_to_bytes('2T')).to   eq(2_199_023_255_552)
    end

    it 'size_to_bytes returns nil for relative specs' do
      expect(LvmHelper.size_to_bytes('10%VG')).to be_nil
    end
  end
end
