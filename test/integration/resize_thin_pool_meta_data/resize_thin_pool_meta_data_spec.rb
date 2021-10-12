describe command 'lvs --options meta_data_lv,lv_metadata_size' do
  its('stdout') { should match /\[lv-thin_tmeta\]\s+128.00m/ }
end
