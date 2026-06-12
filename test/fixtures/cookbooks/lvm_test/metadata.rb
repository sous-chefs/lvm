# frozen_string_literal: true
name             'lvm_test'
description      'Test fixture cookbook for the lvm cookbook'
version          '0.1.0'
chef_version     '>= 17'

# Depend on the lvm cookbook being under test
depends 'lvm'
