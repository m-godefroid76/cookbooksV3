#
# Cookbook Name:: symlink
# Recipe:: default
# encoding: utf-8
#

link '/mnt/srv/www/wordpress/current/wp-content/uploads' do
  to '/mnt/uploads/wp-content/uploads'
end

template '/srv/www/wordpress/current/.htaccess' do
  source 'htaccess.erb'
  owner 'root'
  group 'root'
  mode '0444'
end

template '/srv/www/wordpress/current/wp-content/plugins/opengraphy/files/config.php' do
  source 'config.resto_be.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/srv/www/wordpress/current/wp-content/plugins/opengraphy/files/resto_fr/config.php' do
  source 'config.resto_fr.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/srv/www/wordpress/current/wp-cron-mu.php' do
  source 'wp-cron-mu.php.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/logrotate.conf' do
  source 'logrotate.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/logrotate.d/apache2' do
  source 'apache2.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/root/.s3cfg' do
  source 's3cfg.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

template '/srv/www/wordpress/current/health-check.php' do
  source 'health-check.php.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

directory '/srv/www/wordpress/current/wp-content/w3tc-config' do
  owner 'www-data'
  group 'www-data'
  mode '0777'
  action :create
end

template '/srv/www/wordpress/current/wp-content/w3tc-config/master.php' do
  source 'master.php.erb'
  owner 'www-data'
  group 'www-data'
  mode '0777'
end

template '/srv/www/wordpress/current/wp-content/w3tc-config/master-admin.php' do
  source 'master-admin.php.erb'
  owner 'www-data'
  group 'www-data'
  mode '0777'
end

template '/srv/www/wordpress/current/wp-content/w3tc-config/index.html' do
  source 'index.html.erb'
  owner 'www-data'
  group 'www-data'
  mode '0777'
end

bash "copy logrotate.cron from daily to hourly" do
  user 'root'
  code <<-EOH
  sudo cp /etc/cron.daily/logrotate /etc/cron.hourly/logrotate
  EOH
end

directory '/srv/www/wordpress/current/wp-content/cache' do
  owner 'www-data'
  group 'www-data'
  mode '0755'
  action :create
end

node[:deploy].each do |application, deploy|
  cache_config = "#{deploy[:deploy_to]}/current/wp-content/w3tc-config"
  execute "chmod -R 777 #{cache_config}" do
  end
end

# node[:deploy].each do |application, deploy|
  # cache_config = "#{deploy[:deploy_to]}/current/wp-content/wp-cache-config.php"
  # execute "chmod -R 666 #{cache_config}" do
  # end
# end
