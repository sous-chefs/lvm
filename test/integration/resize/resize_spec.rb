describe command 'lvs' do
  its('stdout') { should match /percent_resize\s+vg-test\s+-wi-ao----\s+48.00m/ }
  its('stdout') { should match /percent_noresize\s+vg-test\s+-wi-ao----\s+24.00m/ }
  its('stdout') { should match /small_resize\s+vg-test\s+-wi-ao----\s+16.00m/ }
  its('stdout') { should match /small_noresize\s+vg-test\s+-wi-ao----\s+8.00m/ }
  its('stdout') { should match /remainder_resize\s+vg-test\s+-wi-ao----\s+128.00m/ }
end

describe command 'vgs' do
  its('stdout') { should match /vg-test\s+4\s+8\s+0\s+wz--n-\s+496.00m\s+0/ }
end

describe command 'pvs' do
  its('stdout') { should match %r{dev/loop0\s+vg-data\s+lvm2\s+a--\s+156.00m\s+136.00m} }
end
