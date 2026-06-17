# frozen_string_literal: true

control 'remove-physical-volumes' do
  impact 1.0
  title 'Physical volumes remain after LV removal'

  %w(/dev/loop10 /dev/loop11 /dev/loop12 /dev/loop13).each do |device|
    describe command("pvs #{device}") do
      its('exit_status') { should eq 0 }
    end

    describe command("pvs --noheadings -o vg_name #{device}") do
      its('stdout') { should match 'vg-rmdata' }
    end
  end
end

control 'remove-logical-volumes' do
  impact 1.0
  title 'Logical volumes are removed'

  describe command('lvs vg-rmdata/rmlogs') do
    its('exit_status') { should_not eq 0 }
  end

  describe command('lvs vg-rmdata/rmtest') do
    its('exit_status') { should_not eq 0 }
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
