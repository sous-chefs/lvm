# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_thin_volume' do
  platform 'ubuntu', '22.04'

  context 'with action :create' do
    recipe do
      lvm_thin_volume 'tv_data' do
        group 'vg_data'
        pool 'tp_data'
        size '20G'
      end
    end

    it 'creates a thin volume' do
      expect(chef_run).to create_lvm_thin_volume('tv_data')
        .with(group: 'vg_data', pool: 'tp_data', size: '20G')
    end
  end

  context 'with action :resize' do
    recipe do
      lvm_thin_volume 'tv_data' do
        group 'vg_data'
        pool 'tp_data'
        size '40G'
        action :resize
      end
    end

    it 'resizes the thin volume' do
      expect(chef_run).to resize_lvm_thin_volume('tv_data')
    end
  end
end
