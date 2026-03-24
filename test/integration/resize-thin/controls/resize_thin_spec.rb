# frozen_string_literal: true

control 'resize-thin-volume' do
  impact 1.0
  title 'Thin volume is resized'

  describe command 'lvs' do
    its('stdout') { should match(/thin_vol_1\s+vg-test\s+Vwi-aotz--\s+32.00m\s+lv-thin/) }
  end
end
