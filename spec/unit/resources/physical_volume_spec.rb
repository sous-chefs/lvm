# frozen_string_literal: true

require 'spec_helper'

describe 'lvm_physical_volume' do
  platform 'ubuntu', '22.04'

  context 'with action :create' do
    recipe do
      lvm_physical_volume '/dev/sdb'
    end

    it 'creates a physical volume' do
      expect(chef_run).to create_lvm_physical_volume('/dev/sdb')
    end
  end

  context 'with wipe_signatures enabled' do
    recipe do
      lvm_physical_volume '/dev/sdb' do
        wipe_signatures true
      end
    end

    it 'creates a physical volume with wipe_signatures' do
      expect(chef_run).to create_lvm_physical_volume('/dev/sdb')
        .with(wipe_signatures: true)
    end
  end

  context 'with action :resize' do
    recipe do
      lvm_physical_volume '/dev/sdb' do
        action :resize
      end
    end

    it 'resizes a physical volume' do
      expect(chef_run).to resize_lvm_physical_volume('/dev/sdb')
    end
  end
end
