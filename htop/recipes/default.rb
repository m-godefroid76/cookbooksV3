#
# Cookbook Name:: htop
# Recipe:: default
# encoding: utf-8
#

case node[:platform] 
when "ubuntu","debian"
  package "htop" do
    action :install
  end
end

template '/mnt/srv/www/wordpress/current/wp-config.php' do
  source 'wp-config.php.erb'
  owner 'root'
  group 'root'
  mode '0444'
end