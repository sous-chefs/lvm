# frozen_string_literal: true

control 'remove-physical-volumes' do
  impact 1.0
  title 'Physical volumes remain after LV removal'

  describe command 'pvs' do
    its('stdout') { should match %r{/dev/loop10\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
    its('stdout') { should match %r{/dev/loop11\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
    its('stdout') { should match %r{/dev/loop12\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
    its('stdout') { should match %r{/dev/loop13\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
  end
end

control 'remove-logical-volumes' do
  impact 1.0
  title 'Logical volumes are removed'

  describe command 'lvs' do
    its('stdout') { should_not match 'rmlogs' }
    its('stdout') { should_not match 'rmtest' }
  end
end

control 'remove-mount-directories' do
  impact 1.0
  title 'Mount directories handled correctly after removal'

  describe directory '/mnt/rmlogs' do
    it { should exist }
    its('mode') { should cmp '0755' }
  end

  describe directory '/mnt/rmtest' do
    it { should_not exist }
  end
end
