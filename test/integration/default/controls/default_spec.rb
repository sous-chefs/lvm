# frozen_string_literal: true

control 'lvm-packages' do
  impact 1.0
  title 'LVM packages are installed'
  desc 'Verify that lvm2 package is installed'

  describe package('lvm2') do
    it { should be_installed }
  end

  if os.debian?
    describe package('thin-provisioning-tools') do
      it { should be_installed }
    end
  end
end

control 'lvm-physical-volumes' do
  impact 1.0
  title 'Physical volumes are created'
  desc 'Verify that physical volumes exist on loop devices'

  %w(/dev/loop10 /dev/loop11 /dev/loop12 /dev/loop13).each do |device|
    describe command("pvs #{device}") do
      its('exit_status') { should eq 0 }
    end
  end
end

control 'lvm-volume-group' do
  impact 1.0
  title 'Volume group is created'
  desc 'Verify that the vg-data volume group exists'

  describe command('vgs vg-data') do
    its('exit_status') { should eq 0 }
  end
end

control 'lvm-logical-volumes' do
  impact 1.0
  title 'Logical volumes are created'
  desc 'Verify that logical volumes exist in vg-data'

  describe command('lvs vg-data/logs') do
    its('exit_status') { should eq 0 }
  end

  describe command('lvs vg-data/home') do
    its('exit_status') { should eq 0 }
  end
end

control 'lvm-mount-points' do
  impact 1.0
  title 'Logical volumes are mounted'
  desc 'Verify that logical volumes are mounted at the correct locations'

  describe mount('/mnt/logs') do
    it { should be_mounted }
    its('type') { should eq 'ext2' }
  end

  describe mount('/mnt/home') do
    it { should be_mounted }
    its('type') { should eq 'ext2' }
  end
end
