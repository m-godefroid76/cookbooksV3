name 'swap'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures swap'
long_description 'Installs/Configures swap'
version '0.1.0'

recipe 'swap', 'Installs/Configures swap'

%w(centos debian ubuntu).each do |os|
  supports os
end
