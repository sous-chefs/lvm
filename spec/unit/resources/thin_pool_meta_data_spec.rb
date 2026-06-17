# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_thin_pool_meta_data' do
  platform 'ubuntu', '24.04'

  context 'action :resize' do
    recipe do
      lvm_thin_pool_meta_data 'lv-thin_tmeta' do
        group 'vg-data'
        pool 'lv-thin'
        size '128M'
      end
    end

    it { is_expected.to resize_lvm_thin_pool_meta_data('lv-thin_tmeta') }
    it { is_expected.to resize_lvm_thin_pool_meta_data('lv-thin_tmeta').with(pool: 'lv-thin', size: '128M') }
  end
end
