%w{ build-essential pkg-config libcurl4-openssl-dev libfuse-dev libfuse2 libxml2-dev mime-support }.each do |pkg|
  package pkg
end

# install fuse
remote_file "/tmp/fuse-#{ node[:fuse][:version] }.tar.gz" do
  # source "http://downloads.sourceforge.net/project/fuse/fuse-2.X/#{ node[:fuse][:version] }/fuse-#{ node[:fuse][:version] }.tar.gz"
  # source "http://pkgs.fedoraproject.org/repo/pkgs/fuse/fuse-2.8.7.tar.gz/"
  source "ftp://ftp.gnome.org/mirror/temp/sf2015/f/fu/fuse/fuse-2.X/2.8.7/fuse-2.8.7.tar.gz"
  mode 0644
end

bash "install fuse" do
  cwd "/tmp"
  code <<-EOH
  tar zxvf fuse-#{ node[:fuse][:version] }.tar.gz
  cd fuse-#{ node[:fuse][:version] }
  ./configure --prefix=/usr
  make
  sudo make install

  EOH

  not_if { File.exists?("/usr/bin/fusermount") }
end

remote_file "/tmp/s3fs-#{ node[:s3fs][:version] }.tar.gz" do
  source "http://s3fs.googlecode.com/files/s3fs-#{ node[:s3fs][:version] }.tar.gz"
  mode 0644
end

bash "install s3fs" do
  cwd "/tmp"
  code <<-EOH
  tar zxvf s3fs-#{ node[:s3fs][:version] }.tar.gz
  cd s3fs-#{ node[:s3fs][:version] }
  ./configure --prefix=/usr
  make
  sudo make install
  EOH

  not_if { File.exists?("/usr/bin/s3fs") }
end

directory "/tmp/cache" do
  mode "0777"
  owner "root"
  group "root"
  action :create
  recursive true
end

directory "/mnt/uploads" do
  mode "0755"
  owner "root"
  group "root"
  action :create
  recursive true
end

file '/etc/passwd-s3fs' do
  content "#{ node[:access_key] }:#{ node[:secret_key] }"	
end

file '/etc/passwd-s3fs' do
  mode "0640"
end

file '/etc/fuse.conf' do
  content  "user_allow_other"
end

execute 'mount uploads folder' do
  user "root"
  command "sudo s3fs #{ node[:bucket] } -o allow_other,use_cache=/tmp/cache /mnt/uploads"
end
