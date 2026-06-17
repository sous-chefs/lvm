# frozen_string_literal: true

control 'create-physical-volumes' do
  impact 1.0
  title 'Physical volumes are created'

  {
    '/dev/loop10' => 'vg-data',
    '/dev/loop11' => 'vg-data',
    '/dev/loop12' => 'vg-data',
    '/dev/loop13' => 'vg-data',
    '/dev/loop14' => 'vg-test',
    '/dev/loop15' => 'vg-test',
    '/dev/loop16' => 'vg-test',
    '/dev/loop17' => 'vg-test',
  }.each do |device, vg|
    describe command("pvs #{device}") do
      its('exit_status') { should eq 0 }
    end

    describe command("pvs --noheadings -o vg_name #{device}") do
      its('stdout') { should match vg }
    end
  end
end

control 'create-volume-groups' do
  impact 1.0
  title 'Volume groups are created'

  describe command('vgs vg-data') do
    its('exit_status') { should eq 0 }
  end

  describe command('vgs --noheadings -o pv_count vg-data') do
    its('stdout') { should match '4' }
  end

  describe command('vgs --noheadings -o lv_count vg-data') do
    its('stdout') { should match '2' }
  end

  describe command('vgs vg-test') do
    its('exit_status') { should eq 0 }
  end

  describe command('vgs --noheadings -o pv_count vg-test') do
    its('stdout') { should match '4' }
  end

  describe command('vgs --noheadings -o lv_count vg-test') do
    its('stdout') { should match '2' }
  end
end

control 'create-logical-volumes' do
  impact 1.0
  title 'Logical volumes are created'

  [
    %w(vg-data logs),
    %w(vg-data home),
    %w(vg-test test),
    %w(vg-test small),
  ].each do |vg, lv|
    describe command("lvs --noheadings -o lv_name,lv_size --units m --nosuffix #{vg}/#{lv}") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match lv }
    end
  end
end

control 'create-mount-points' do
  impact 1.0
  title 'Logical volumes are mounted correctly'

  describe mount '/mnt/logs' do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/vg--data-logs' }
    its('type') { should eq 'ext2' }
  end

  describe mount '/mnt/home' do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/vg--data-home' }
    its('type') { should eq 'ext2' }
  end

  describe mount '/mnt/test' do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/vg--test-test' }
    its('type') { should eq 'ext3' }
  end

  describe mount '/mnt/small' do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/vg--test-small' }
    its('type') { should eq 'ext3' }
  end
end

control 'create-directory-permissions' do
  impact 1.0
  title 'Directory permissions are set correctly'

  describe directory '/mnt/small' do
    its('mode') { should cmp '0555' }
  end
end
