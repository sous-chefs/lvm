# frozen_string_literal: true

name 'lvm'

default_source :supermarket

cookbook 'lvm', path: '.'
cookbook 'test', path: 'test/cookbooks/test'
