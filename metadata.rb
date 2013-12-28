name              'lvm'
maintainer        'Opscode, Inc.'
maintainer_email  'cookbooks@opscode.com'
license           'Apache 2.0'
description       'Installs lvm2 package'
version           '1.0.5'

supports 'centos'
supports 'debian'
supports 'redhat'
supports 'sles'
supports 'ubuntu'

recipe 'lvm', 'Installs lvm2 package'
