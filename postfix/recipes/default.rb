template '/etc/postfix/main.cf' do
  source 'main.cf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/postfix/sasl_passwd' do
  source 'sasl_passwd.erb'
  owner 'root'
  group 'root'
  mode '0400'
end

bash "postmap passwd" do
  user 'root'
  code <<-EOH
  sudo postmap /etc/postfix/sasl_passwd
  EOH
end

bash "install certificate" do
  user 'root'
  code <<-EOH
  cat /etc/ssl/certs/Starfield_Class_2_CA.pem | sudo tee -a /etc/postfix/cacert.pem
  EOH
end

bash "cat certs" do
  user 'root'
  code <<-EOH
  cat /etc/ssl/certs/Thawte_Premium_Server_CA.pem | sudo tee -a /etc/postfix/cacert.pem
  EOH
end

bash "cat certs" do
  user 'root'
  code <<-EOH
  sudo /etc/init.d/postfix reload
  EOH
end
