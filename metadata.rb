name 'lvm'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Installs and manages Logical Volume Manager'
version '5.0.2'
%w(amazon centos fedora freebsd oracle redhat scientific suse ubuntu).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/lvm'
issues_url 'https://github.com/chef-cookbooks/lvm/issues'
chef_version '>= 12.15'
