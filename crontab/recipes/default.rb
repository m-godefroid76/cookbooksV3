cron "wp-cron" do
    action :create
    minute "*/10"
    command '/usr/bin/php /srv/www/wordpress/current/wp-cron-mu.php > /var/log/cron.log 1>&1'
end

cron "logrotate" do
    action :create
    minute "0"
    hour '2'
    command '/usr/sbin/logrotate /etc/logrotate.conf > /var/log/cron.log 1>&1'
end

cron "backup-db" do
    action :create
    minute '0'
    hour '2'
    weekday "1"
    command '/scripts/backup-db.sh > /var/log/cron.log 1>&1'
end

