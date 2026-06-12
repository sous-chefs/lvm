# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_thin_pool_meta_data' do
  platform 'ubuntu', '22.04'

  context 'with action :resize' do
    recipe do
      lvm_thin_pool_meta_data 'tp_data_tmeta' do
        group 'vg_data'
        pool 'tp_data'
        size '512M'
      end
    end

    it 'resizes the thin pool metadata' do
      expect(chef_run).to resize_lvm_thin_pool_meta_data('tp_data_tmeta')
        .with(group: 'vg_data', pool: 'tp_data', size: '512M')
    end
  end
end
