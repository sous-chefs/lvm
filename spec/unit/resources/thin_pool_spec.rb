# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_thin_pool' do
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      lvm_thin_pool 'lv-thin' do
        group 'vg-data'
        size '64M'
      end
    end

    it { is_expected.to create_lvm_thin_pool('lv-thin') }
    it { is_expected.to create_lvm_thin_pool('lv-thin').with(group: 'vg-data', size: '64M') }
  end

  context 'action :create with nested thin volumes' do
    recipe do
      lvm_thin_pool 'lv-thin' do
        group 'vg-data'
        size '64M'

        thin_volume 'thin_vol_1' do
          size '32M'
          filesystem 'ext4'
          mount_point '/mnt/thin1'
        end
      end
    end

    it { is_expected.to create_lvm_thin_pool('lv-thin') }
  end

  context 'action :resize' do
    recipe do
      lvm_thin_pool 'lv-thin' do
        group 'vg-data'
        size '128M'
        action :resize
      end
    end

    it { is_expected.to resize_lvm_thin_pool('lv-thin') }
  end

  context 'action :create with percentage size' do
    recipe do
      lvm_thin_pool 'lv-thin' do
        group 'vg-data'
        size '50%VG'
      end
    end

    it { is_expected.to create_lvm_thin_pool('lv-thin').with(size: '50%VG') }
  end
end
