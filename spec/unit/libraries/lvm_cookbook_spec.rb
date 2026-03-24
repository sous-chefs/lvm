# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/lvm'

describe LVMCookbook do
  describe 'gem version defaults' do
    it 'has a default LVM gem version' do
      expect(LVMCookbook::LVM_GEM_VERSION).to eq '0.4.3'
    end

    it 'has a default LVM attrib gem version' do
      expect(LVMCookbook::LVM_ATTRIB_GEM_VERSION).to eq '0.6.0'
    end
  end

  describe '#lvm_gem_version' do
    let(:helper_class) do
      Class.new do
        include LVMCookbook

        attr_reader :node

        def initialize(node)
          @node = node
        end
      end
    end

    context 'when node attributes are not set' do
      let(:node) { { 'lvm' => {} } }
      let(:helper) { helper_class.new(node) }

      it 'returns the default LVM gem version' do
        expect(helper.lvm_gem_version).to eq '0.4.3'
      end

      it 'returns the default LVM attrib gem version' do
        expect(helper.lvm_attrib_gem_version).to eq '0.6.0'
      end
    end

    context 'when node attributes are set' do
      let(:node) { { 'lvm' => { 'chef-ruby-lvm-version' => '0.5.0', 'chef-ruby-lvm-attrib-version' => '0.7.0' } } }
      let(:helper) { helper_class.new(node) }

      it 'returns the overridden LVM gem version' do
        expect(helper.lvm_gem_version).to eq '0.5.0'
      end

      it 'returns the overridden LVM attrib gem version' do
        expect(helper.lvm_attrib_gem_version).to eq '0.7.0'
      end
    end
  end
end
