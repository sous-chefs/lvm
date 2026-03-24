# frozen_string_literal: true

control 'resize-logical-volumes' do
  impact 1.0
  title 'Logical volumes are resized correctly'

  describe command 'lvs' do
    its('stdout') { should match(/percent_resize\s+vg-test\s+-wi-ao----\s+48.00m/) }
    its('stdout') { should match(/percent_noresize\s+vg-test\s+-wi-ao----\s+24.00m/) }
    its('stdout') { should match(/small_resize\s+vg-test\s+-wi-ao----\s+16.00m/) }
    its('stdout') { should match(/small_noresize\s+vg-test\s+-wi-ao----\s+8.00m/) }
    its('stdout') { should match(/remainder_resize\s+vg-test\s+-wi-ao----\s+128.00m/) }
  end
end

control 'resize-volume-groups' do
  impact 1.0
  title 'Volume groups reflect resized volumes'

  describe command 'vgs' do
    its('stdout') { should match(/vg-test\s+4\s+8\s+0\s+wz--n-\s+496.00m\s+0/) }
  end
end

control 'resize-physical-volumes' do
  impact 1.0
  title 'Physical volumes reflect resized volumes'

  describe command 'pvs' do
    its('stdout') { should match %r{dev/loop10\s+vg-data\s+lvm2\s+a--\s+124.00m\s+104.00m} }
  end
end
