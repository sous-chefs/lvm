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

  context 'action :create with lv_name property' do
    recipe do
      lvm_logical_volume 'my_resource' do
        lv_name 'actual-lv-name'
        group 'vg-data'
        size '10M'
      end
    end

    it { is_expected.to create_lvm_logical_volume('my_resource').with(lv_name: 'actual-lv-name') }
  end

  context 'action :create with take_up_free_space' do
    recipe do
      lvm_logical_volume 'free_space_lv' do
        group 'vg-data'
        take_up_free_space true
        filesystem 'ext4'
        mount_point '/mnt/free'
      end
    end

    it { is_expected.to create_lvm_logical_volume('free_space_lv').with(take_up_free_space: true) }
  end

  context 'action :create with ignore_skipped_cluster' do
    recipe do
      lvm_logical_volume 'cluster_lv' do
        group 'vg-data'
        size '10M'
        ignore_skipped_cluster true
      end
    end

    it { is_expected.to create_lvm_logical_volume('cluster_lv').with(ignore_skipped_cluster: true) }
  end

  context 'action :create with lv_params' do
    recipe do
      lvm_logical_volume 'params_lv' do
        group 'vg-data'
        size '10M'
        lv_params '--type raid1'
      end
    end

    it { is_expected.to create_lvm_logical_volume('params_lv').with(lv_params: '--type raid1') }
  end

  context 'action :create with mount_point as a hash' do
    recipe do
      lvm_logical_volume 'hash_mount_lv' do
        group 'vg-data'
        size '10M'
        filesystem 'ext4'
        mount_point location: '/mnt/data', options: 'noatime,nodiratime', dump: 0, pass: 2
      end
    end

    it do
      is_expected.to create_lvm_logical_volume('hash_mount_lv').with(
        mount_point: { location: '/mnt/data', options: 'noatime,nodiratime', dump: 0, pass: 2 }
      )
    end
  end

  context 'action :create with contiguous and readahead' do
    recipe do
      lvm_logical_volume 'tuned_lv' do
        group 'vg-data'
        size '10M'
        contiguous true
        readahead 'auto'
      end
    end

    it { is_expected.to create_lvm_logical_volume('tuned_lv').with(contiguous: true, readahead: 'auto') }
  end

  context 'action :create with stripe_size' do
    recipe do
      lvm_logical_volume 'stripe_lv' do
        group 'vg-data'
        size '10M'
        stripes 2
        stripe_size 64
      end
    end

    it { is_expected.to create_lvm_logical_volume('stripe_lv').with(stripes: 2, stripe_size: 64) }
  end
end
