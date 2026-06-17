# frozen_string_literal: true

control 'resize-thin-pool-metadata' do
  impact 1.0
  title 'Thin pool metadata is resized'

  describe command('lvs vg-test/lv-thin') do
    its('exit_status') { should eq 0 }
  end

  # Metadata size should be >= 128m after resize
  describe command('lvs --noheadings --nosuffix --units m -o lv_metadata_size vg-test/lv-thin') do
    its('stdout') { should match(/^\s*1[2-9]\d|[2-9]\d\d|\d{4,}/) }
  end
end
