# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_logical_volume' do
  platform 'ubuntu', '24.04'

  context 'action :create with default properties' do
    recipe do
      lvm_logical_volume 'test_lv' do
        group 'vg-data'
        size '10M'
        filesystem 'ext4'
        mount_point '/mnt/test'
      end
    end

    it { is_expected.to create_lvm_logical_volume('test_lv') }
    it { is_expected.to create_lvm_logical_volume('test_lv').with(group: 'vg-data', size: '10M', filesystem: 'ext4') }
  end

  context 'action :create with stripes and mirrors' do
    recipe do
      lvm_logical_volume 'striped_lv' do
        group 'vg-data'
        size '10M'
        stripes 2
        mirrors 1
        filesystem 'ext4'
        mount_point '/mnt/striped'
      end
    end

    it { is_expected.to create_lvm_logical_volume('striped_lv').with(stripes: 2, mirrors: 1) }
  end

  context 'action :create with percentage size' do
    recipe do
      lvm_logical_volume 'percent_lv' do
        group 'vg-data'
        size '50%VG'
        filesystem 'ext3'
      end
    end

    it { is_expected.to create_lvm_logical_volume('percent_lv').with(size: '50%VG') }
  end

  context 'action :resize' do
    recipe do
      lvm_logical_volume 'test_lv' do
        group 'vg-data'
        size '20M'
        action :resize
      end
    end

    it { is_expected.to resize_lvm_logical_volume('test_lv') }
  end

  context 'action :remove' do
    recipe do
      lvm_logical_volume 'test_lv' do
        group 'vg-data'
        size '10M'
        action :remove
      end
    end

    it { is_expected.to remove_lvm_logical_volume('test_lv') }
  end

  context 'action :remove with remove_mount_point' do
    recipe do
      lvm_logical_volume 'test_lv' do
        group 'vg-data'
        size '10M'
        mount_point '/mnt/test'
        remove_mount_point true
        action :remove
      end
    end

    it { is_expected.to remove_lvm_logical_volume('test_lv').with(remove_mount_point: true) }
  end
end
