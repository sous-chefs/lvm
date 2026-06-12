# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_logical_volume' do
  platform 'ubuntu', '22.04'

  context 'with action :create' do
    recipe do
      lvm_logical_volume 'lv_data' do
        group 'vg_data'
        size '10G'
      end
    end

    it 'creates a logical volume' do
      expect(chef_run).to create_lvm_logical_volume('lv_data')
        .with(group: 'vg_data', size: '10G')
    end
  end

  context 'with filesystem and mount_point' do
    recipe do
      lvm_logical_volume 'lv_data' do
        group 'vg_data'
        size '10G'
        filesystem 'ext4'
        mount_point '/mnt/data'
      end
    end

    it 'creates a logical volume with filesystem' do
      expect(chef_run).to create_lvm_logical_volume('lv_data')
        .with(filesystem: 'ext4', mount_point: '/mnt/data')
    end
  end

  context 'with stripes and mirrors' do
    recipe do
      lvm_logical_volume 'lv_striped' do
        group 'vg_data'
        size '5G'
        stripes 2
        stripe_size 64
      end
    end

    it 'creates a striped logical volume' do
      expect(chef_run).to create_lvm_logical_volume('lv_striped')
        .with(stripes: 2, stripe_size: 64)
    end
  end

  context 'with action :resize' do
    recipe do
      lvm_logical_volume 'lv_data' do
        group 'vg_data'
        size '20G'
        action :resize
      end
    end

    it 'resizes the logical volume' do
      expect(chef_run).to resize_lvm_logical_volume('lv_data')
    end
  end

  context 'with action :remove' do
    recipe do
      lvm_logical_volume 'lv_data' do
        group 'vg_data'
        size '10G'
        action :remove
      end
    end

    it 'removes the logical volume' do
      expect(chef_run).to remove_lvm_logical_volume('lv_data')
    end
  end
end
