name 'test'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'A test cookbook for lvm'
version '0.1.0'
# The 'test' recipe loop_devices resource requires ruby 2.4.x to operate
# therefore a minimum chef client needed is 13.0
chef_version '>= 13.0' if respond_to?(:chef_version)

depends 'lvm'
