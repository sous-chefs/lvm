# frozen_string_literal: true

name 'lvm'

run_list 'test::default'

named_run_list :create, 'test::create'
named_run_list :remove, 'test::remove'
named_run_list :create_thin, 'test::create_thin'
named_run_list :resize, 'test::create', 'test::resize'
named_run_list :resize_thin, 'test::create_thin', 'test::resize_thin'
named_run_list :resize_thin_pool_meta_data, 'test::create_thin', 'test::resize_thin_pool_meta_data'

cookbook 'lvm', path: '.'
cookbook 'test', path: 'test/cookbooks/test'
