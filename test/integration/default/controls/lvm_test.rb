# frozen_string_literal: true

# LVM integration tests — verify packages installed and LVM is functional.

describe package('lvm2') do
  it { should be_installed }
end

describe command('lvm version') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/LVM version/) }
end

describe command('pvs --reportformat json 2>/dev/null') do
  its('exit_status') { should eq 0 }
end

describe command('vgs --reportformat json 2>/dev/null') do
  its('exit_status') { should eq 0 }
end

describe command('lvs --reportformat json 2>/dev/null') do
  its('exit_status') { should eq 0 }
end

# Verify PVs backing our test VG exist
describe command('pvs --select "vg_name=vg_test" --reportformat json --units b --nosuffix 2>/dev/null') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/vg_test/) }
end

describe command('vgs vg_test --reportformat json --units b --nosuffix 2>/dev/null') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/vg_test/) }
end

describe command('lvs vg_test/lv_data --reportformat json --units b --nosuffix 2>/dev/null') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/lv_data/) }
end

describe mount('/mnt/lvm-test') do
  it { should be_mounted }
  its('device') { should match(%r{/dev/mapper/vg_test-lv_data}) }
  its('type') { should eq 'ext4' }
end
