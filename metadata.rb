name              'lvm'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Installs and manages Logical Volume Manager'
version           '6.2.6'
source_url        'https://github.com/sous-chefs/lvm'
issues_url        'https://github.com/sous-chefs/lvm/issues'
chef_version      '>= 17'

supports 'redhat',       '>= 7.0'   # RHEL 7–10
supports 'centos',       '>= 7.0'
supports 'rocky'
supports 'alma'
supports 'fedora'
supports 'ubuntu',       '>= 18.04' # Ubuntu 18.04–26.04 LTS
supports 'debian',       '>= 10.0'
supports 'suse',         '>= 15.0'  # SLES 15 SP5, SP6
supports 'opensuseleap'
supports 'oracle', '>= 7.0'
supports 'amazon'
