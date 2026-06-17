# frozen_string_literal: true

control 'thin-physical-volumes' do
  impact 1.0
  title 'Physical volumes for thin provisioning'

  {
    '/dev/loop10' => 'vg-data',
    '/dev/loop11' => 'vg-data',
    '/dev/loop12' => 'vg-test',
    '/dev/loop13' => 'vg-test',
  }.each do |device, vg|
    describe command("pvs #{device}") do
      its('exit_status') { should eq 0 }
    end

    describe command("pvs --noheadings -o vg_name #{device}") do
      its('stdout') { should match vg }
    end
  end
end

control 'thin-logical-volumes' do
  impact 1.0
  title 'Thin pool and thin volumes are created'

  %w(tpool tvol01 tvol02).each do |lv|
    describe command("lvs vg-data/#{lv}") do
      its('exit_status') { should eq 0 }
    end
  end

  describe command('lvs --noheadings -o pool_lv vg-data/tvol01') do
    its('stdout') { should match 'tpool' }
  end

  describe command('lvs --noheadings -o pool_lv vg-data/tvol02') do
    its('stdout') { should match 'tpool' }
  end
end

control 'thin-mount-points' do
  impact 1.0
  title 'Thin volumes are mounted'

  describe mount '/mnt/tvol01' do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/vg--data-tvol01' }
    its('type') { should eq 'ext2' }
  end

  describe mount '/mnt/tvol02' do
    it { should be_mounted }
    its('device') { should eq '/dev/mapper/vg--data-tvol02' }
    its('type') { should eq 'ext2' }
  end
end
