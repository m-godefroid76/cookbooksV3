#
# Cookbook Name:: shutdown
# Recipe:: default
# encoding: utf-8
#

bash "logrotate on shutdown" do
  user 'root'
  command 'sudo /usr/sbin/logrotate -f /etc/logrotate.conf'
  action :nothing
end

# directory '/srv/www/wordpress/current/uploads' do
  # recursive false
  # action :delete
# end

bash "unmount s3fs" do
  user 'root'
  command 'sudo umount /mnt//uploads/'
  action :nothing
end

# bash "move logrotate.cron from daily to hourly" do
  # user 'root'
  # code <<-EOH
  # sudo mv /etc/cron.hourly/logrotate /etc/cron.daily/logrotate
  # EOH
# end