describe command 'pvs' do
  its('stdout') { should match %r{/dev/loop10\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
  its('stdout') { should match %r{/dev/loop11\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
  its('stdout') { should match %r{/dev/loop12\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
  its('stdout') { should match %r{/dev/loop13\s+vg-rmdata\s+lvm2\s+a--\s+124.00m\s+124.00m} }
end

describe command 'lvs' do
  its('stdout') { should_not match 'rmlogs' }
  its('stdout') { should_not match 'rmtest' }
end

describe directory '/mnt/rmlogs' do
  it { should exist }
  its('mode') { should cmp '0755' }
end

describe directory '/mnt/rmtest' do
  it { should_not exist }
end
