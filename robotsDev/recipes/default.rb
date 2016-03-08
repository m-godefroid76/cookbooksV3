template '/mnt/srv/www/wordpress/current/robots.txt' do
  source 'robots.txt.erb'
  owner 'root'
  group 'root'
  mode '0644'
end 
