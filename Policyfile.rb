# frozen_string_literal: true

name 'lvm'

default_source :supermarket

run_list 'test::default'

cookbook 'lvm', path: '.'
cookbook 'test', path: 'test/cookbooks/test'
