# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_thin_pool' do
  platform 'ubuntu', '22.04'

  context 'with action :create' do
    recipe do
      lvm_thin_pool 'tp_data' do
        group 'vg_data'
        size '8G'
      end
    end

    it 'creates a thin pool' do
      expect(chef_run).to create_lvm_thin_pool('tp_data')
        .with(group: 'vg_data', size: '8G')
    end
  end

  context 'with action :resize' do
    recipe do
      lvm_thin_pool 'tp_data' do
        group 'vg_data'
        size '16G'
        action :resize
      end
    end

    it 'resizes the thin pool' do
      expect(chef_run).to resize_lvm_thin_pool('tp_data')
    end
  end

  context 'with action :remove' do
    recipe do
      lvm_thin_pool 'tp_data' do
        group 'vg_data'
        size '8G'
        action :remove
      end
    end

    it 'removes the thin pool' do
      expect(chef_run).to remove_lvm_thin_pool('tp_data')
    end
  end
end
