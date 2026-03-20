# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_thin_volume' do
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      lvm_thin_volume 'thin_vol_1' do
        group 'vg-data'
        pool 'lv-thin'
        size '32M'
        filesystem 'ext4'
        mount_point '/mnt/thin1'
      end
    end

    it { is_expected.to create_lvm_thin_volume('thin_vol_1') }
    it { is_expected.to create_lvm_thin_volume('thin_vol_1').with(pool: 'lv-thin', size: '32M') }
  end

  context 'action :resize' do
    recipe do
      lvm_thin_volume 'thin_vol_1' do
        group 'vg-data'
        pool 'lv-thin'
        size '64M'
        action :resize
      end
    end

    it { is_expected.to resize_lvm_thin_volume('thin_vol_1') }
  end
end
