# frozen_string_literal: true

control 'resize-logical-volumes' do
  impact 1.0
  title 'Logical volumes are resized correctly'

  # percent_resize: resized to 48m (>= 48)
  describe command('lvs --noheadings --nosuffix --units m -o lv_size vg-test/percent_resize') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/^\s*4[89]|[5-9]\d|\d{3,}/) }
  end

  # percent_noresize: stays at 24m (>= 24)
  describe command('lvs --noheadings --nosuffix --units m -o lv_size vg-test/percent_noresize') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/^\s*2[4-9]|[3-9]\d|\d{3,}/) }
  end

  # small_resize: resized to 16m (>= 16)
  describe command('lvs --noheadings --nosuffix --units m -o lv_size vg-test/small_resize') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/^\s*1[6-9]|[2-9]\d|\d{3,}/) }
  end

  # small_noresize: stays at 8m (>= 8)
  describe command('lvs --noheadings --nosuffix --units m -o lv_size vg-test/small_noresize') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/^\s*[89]|[1-9]\d|\d{3,}/) }
  end

  # remainder_resize: resized to 128m (>= 128)
  describe command('lvs --noheadings --nosuffix --units m -o lv_size vg-test/remainder_resize') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/^\s*1[2-9]\d|[2-9]\d\d|\d{4,}/) }
  end
end

control 'resize-volume-groups' do
  impact 1.0
  title 'Volume groups reflect resized volumes'

  describe command('vgs vg-test') do
    its('exit_status') { should eq 0 }
  end

  describe command('vgs --noheadings -o pv_count vg-test') do
    its('stdout') { should match '4' }
  end
end

control 'resize-physical-volumes' do
  impact 1.0
  title 'Physical volumes reflect resized volumes'

  describe command('pvs /dev/loop10') do
    its('exit_status') { should eq 0 }
  end

  # Size should be greater than the original 124m — match any value >= 125
  describe command('pvs --noheadings --nosuffix --units m -o pv_size /dev/loop10') do
    its('stdout') { should match(/^\s*1[3-9]\d|[2-9]\d\d|\d{4,}/) }
  end
end
