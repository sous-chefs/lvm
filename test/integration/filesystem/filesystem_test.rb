# frozen_string_literal: true
# InSpec controls: filesystem suite — ext4 + auto-mount

control 'lvm-fs-01' do
  impact 1.0
  title 'LV datalv has an ext4 filesystem'

  describe command('blkid /dev/mapper/datavg-datalv') do
    its('stdout') { should match(/TYPE="ext4"/) }
  end
end

control 'lvm-mount-01' do
  impact 1.0
  title '/data is mounted on datavg/datalv'

  describe mount('/data') do
    it { should be_mounted }
    its('device') { should match(%r{/dev/(mapper/datavg-datalv|datavg/datalv)}) }
    its('type')   { should eq 'ext4' }
  end
end

control 'lvm-fstab-01' do
  impact 1.0
  title '/data has a persistent fstab entry'

  describe file('/etc/fstab') do
    its('content') { should match(%r{/data}) }
  end
end

control 'lvm-dir-01' do
  impact 0.8
  title '/data directory exists and is writable by root'

  describe directory('/data') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('mode')  { should cmp '0755' }
  end
end
