describe command 'lvs' do
  its('stdout') { should match /thin_vol_1\s+vg-test\s+Vwi-aotz--\s+32.00m\s+lv-thin/ }
end
