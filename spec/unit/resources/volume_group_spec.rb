# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_volume_group' do
  platform 'ubuntu', '22.04'

  context 'with action :create' do
    recipe do
      lvm_volume_group 'vg_data' do
        physical_volumes ['/dev/sdb']
      end
    end

    it 'creates a volume group' do
      expect(chef_run).to create_lvm_volume_group('vg_data')
        .with(physical_volumes: ['/dev/sdb'])
    end
  end

  context 'with physical_extent_size' do
    recipe do
      lvm_volume_group 'vg_data' do
        physical_volumes ['/dev/sdb']
        physical_extent_size '8m'
      end
    end

    it 'creates a volume group with custom extent size' do
      expect(chef_run).to create_lvm_volume_group('vg_data')
        .with(physical_extent_size: '8m')
    end
  end

  context 'with action :extend' do
    recipe do
      lvm_volume_group 'vg_data' do
        physical_volumes ['/dev/sdb', '/dev/sdc']
        action :extend
      end
    end

    it 'extends the volume group' do
      expect(chef_run).to extend_lvm_volume_group('vg_data')
    end
  end
end
