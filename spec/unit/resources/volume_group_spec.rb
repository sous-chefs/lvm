# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_volume_group' do
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      lvm_volume_group 'vg-data' do
        physical_volumes ['/dev/sdb', '/dev/sdc']
      end
    end

    it { is_expected.to create_lvm_volume_group('vg-data') }
    it { is_expected.to create_lvm_volume_group('vg-data').with(physical_volumes: ['/dev/sdb', '/dev/sdc']) }
  end

  context 'action :create with physical_extent_size' do
    recipe do
      lvm_volume_group 'vg-data' do
        physical_volumes ['/dev/sdb']
        physical_extent_size '8M'
      end
    end

    it { is_expected.to create_lvm_volume_group('vg-data').with(physical_extent_size: '8M') }
  end

  context 'action :create with nested logical volumes' do
    recipe do
      lvm_volume_group 'vg-data' do
        physical_volumes ['/dev/sdb', '/dev/sdc']

        logical_volume 'logs' do
          size '10M'
          filesystem 'ext4'
          mount_point '/mnt/logs'
        end
      end
    end

    it { is_expected.to create_lvm_volume_group('vg-data') }
  end

  context 'action :extend' do
    recipe do
      lvm_volume_group 'vg-data' do
        physical_volumes ['/dev/sdb', '/dev/sdc', '/dev/sdd']
        action :extend
      end
    end

    it { is_expected.to extend_lvm_volume_group('vg-data') }
  end
end
