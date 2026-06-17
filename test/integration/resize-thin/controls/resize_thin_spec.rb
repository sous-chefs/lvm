# frozen_string_literal: true

control 'resize-thin-volume' do
  impact 1.0
  title 'Thin volume is resized'

  describe command('lvs vg-test/thin_vol_1') do
    its('exit_status') { should eq 0 }
  end

  # Size should be >= 32m after resize
  describe command('lvs --noheadings --nosuffix --units m -o lv_size vg-test/thin_vol_1') do
    its('stdout') { should match(/^\s*3[2-9]|[4-9]\d|\d{3,}/) }
  end
end
