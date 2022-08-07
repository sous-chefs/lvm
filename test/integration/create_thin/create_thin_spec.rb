describe command 'pvs' do
  its('stdout') { should match '/dev/loop10 vg-data' }
  its('stdout') { should match '/dev/loop11 vg-data' }
  its('stdout') { should match '/dev/loop12 vg-test' }
  its('stdout') { should match '/dev/loop13 vg-test' }
end

describe command 'lvs' do
  its('stdout') { should match /tpool\s+vg-data\s+twi-aotz--\s+24.00m/ }
  its('stdout') { should match /tvol01\s+vg-data\s+Vwi-aotz--\s+40.00m\s+tpool/ }
  its('stdout') { should match /tvol02\s+vg-data\s+Vwi-aotz--\s+1.00g\s+tpool/ }
end

describe mount '/mnt/tvol01' do
  it { should be_mounted }
  its('device') { should eq '/dev/mapper/vg--data-tvol01' }
  its('type') { should eq 'ext2' }
end

describe mount '/mnt/tvol02' do
  it { should be_mounted }
  its('device') { should eq '/dev/mapper/vg--data-tvol02' }
  its('type') { should eq 'ext2' }
end
