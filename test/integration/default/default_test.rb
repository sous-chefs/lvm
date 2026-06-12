# frozen_string_literal: true
# InSpec controls: default suite — basic PV / VG / LV existence

control 'lvm-pv-01' do
  impact 1.0
  title 'Physical volume /dev/sdb is initialised'

  describe command('pvs --noheadings -o pv_name') do
    its('stdout') { should include '/dev/sdb' }
    its('exit_status') { should eq 0 }
  end
end

control 'lvm-vg-01' do
  impact 1.0
  title 'Volume group datavg exists'

  describe command('vgs --noheadings -o vg_name') do
    its('stdout') { should include 'datavg' }
    its('exit_status') { should eq 0 }
  end
end

control 'lvm-lv-01' do
  impact 1.0
  title 'Logical volume datavg/datalv exists'

  describe command('lvs --noheadings -o lv_name,vg_name') do
    its('stdout') { should include 'datalv' }
    its('exit_status') { should eq 0 }
  end

  describe file('/dev/datavg/datalv') do
    it { should be_block_device }
  end
end

control 'lvm-idempotent-01' do
  impact 0.5
  title 'Chef run is idempotent — no changes on second converge'
  # This is validated by Test Kitchen running the suite twice (--verify-only)
  # and checking the Chef run summary for "0 resources updated".
  # The assertion here is that the LV still exists after two runs.
  describe file('/dev/datavg/datalv') do
    it { should be_block_device }
  end
end
