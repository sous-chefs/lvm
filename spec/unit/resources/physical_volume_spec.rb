# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_physical_volume' do
  platform 'ubuntu', '24.04'

  context 'action :create' do
    recipe do
      lvm_physical_volume '/dev/sdb'
    end

    it { is_expected.to create_lvm_physical_volume('/dev/sdb') }
  end

  context 'action :create with wipe_signatures' do
    recipe do
      lvm_physical_volume '/dev/sdb' do
        wipe_signatures true
      end
    end

    it { is_expected.to create_lvm_physical_volume('/dev/sdb').with(wipe_signatures: true) }
  end

  context 'action :resize' do
    recipe do
      lvm_physical_volume '/dev/sdb' do
        action :resize
      end
    end

    it { is_expected.to resize_lvm_physical_volume('/dev/sdb') }
  end

  context 'action :create with volume_name property' do
    recipe do
      lvm_physical_volume 'my_pv' do
        volume_name '/dev/sdc'
      end
    end

    it { is_expected.to create_lvm_physical_volume('my_pv').with(volume_name: '/dev/sdc') }
  end
end
