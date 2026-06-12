# frozen_string_literal: true
# InSpec controls: thin suite
# Validates thin pool + lvm_thin_pool_meta + lvm_thin_volume.

control 'lvm-thin-pool-01' do
  impact 1.0
  title 'Thin pool thinvg/thinpool exists with correct LV type'

  describe command('lvs --noheadings -o lv_name,lv_attr,vg_name') do
    its('stdout') { should include 'thinpool' }
    # lv_attr for a thin pool begins with 't'
    its('stdout') { should match(/t\S+\s+thinvg/) }
    its('exit_status') { should eq 0 }
  end
end

control 'lvm-thin-meta-01' do
  impact 1.0
  title 'Thin pool metadata LV [thinpool_tmeta] is >= 256 MiB'

  # lvs --all includes internal/hidden LVs shown with brackets
  describe command('lvs --noheadings --all --units m --nosuffix -o lv_name,lv_size thinvg') do
    its('stdout') { should include '[thinpool_tmeta]' }
    # Value is in MiB; must be >= 256
    its('stdout') do
      should match(/\[thinpool_tmeta\]\s+(\d+)/) do |m|
        m[1].to_f >= 256
      end
    end
  end
end

control 'lvm-thin-meta-spare-01' do
  impact 0.9
  title 'Pool metadata spare is enabled on thinvg'

  # lvs shows the spare LV as [lvol0_pmspare] (name varies) in the VG
  describe command('lvs --noheadings --all -o lv_name,lv_attr thinvg') do
    its('stdout') { should match(/pmspare/) }
  end
end

control 'lvm-thin-lv-01' do
  impact 1.0
  title 'Thin volume thinvg/thinlv exists via lvm_thin_volume resource'

  describe command('lvs --noheadings -o lv_name,lv_attr,vg_name') do
    its('stdout') { should include 'thinlv' }
    # lv_attr for a thin volume begins with 'V'
    its('stdout') { should match(/V\S+\s+thinvg/) }
  end

  describe file('/dev/thinvg/thinlv') do
    it { should be_block_device }
  end
end

control 'lvm-thin-virtualsize-01' do
  impact 0.8
  title 'Thin volume virtual size is 50G (over-provisioned beyond pool size of 10G)'

  describe command('lvs --noheadings -o lv_name,lv_size --units g --nosuffix thinvg') do
    its('stdout') { should match(/thinlv\s+50\./) }
  end
end
