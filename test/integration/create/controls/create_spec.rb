# frozen_string_literal: true

control 'create-physical-volumes' do
  impact 1.0
  title 'Physical volumes are created'

  describe command 'pvs' do
    its('stdout') { should match '/dev/loop10 vg-data' }
    its('stdout') { should match '/dev/loop11 vg-data' }
    its('stdout') { should match '/dev/loop12 vg-data' }
    its('stdout') { should match '/dev/loop13 vg-data' }
    its('stdout') { should match '/dev/loop14 vg-test' }
    its('stdout') { should match '/dev/loop15 vg-test' }
    its('stdout') { should match '/dev/loop16 vg-test' }
    its('stdout') { should match '/dev/loop17 vg-test' }
  end
end

control 'create-volume-groups' do
  impact 1.0
  title 'Volume groups are created'

  describe command 'vgs' do
    its('stdout') { should match(/vg-data\s+4   2   0 wz--n- 496.00m 444.00m/) }
    its('stdout') { should match(/vg-test\s+4   2   0 wz--n- 496.00m 240.00m/) }
  end
end

control 'create-logical-volumes' do
  impact 1.0
  title 'Logical volumes are created'

  describe command 'lvs' do
    its('stdout') { should match(/logs\s+vg-data\s+-wi-ao----  16.00m/) }
    its('stdout') { should match(/home\s+vg-data\s+rwi-aor---   8.00m/) }
    its('stdout') { should match(/test\s+vg-test\s+-wi-ao---- 248.00m/) }
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
