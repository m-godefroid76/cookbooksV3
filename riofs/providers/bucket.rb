action :mount do
    
  if @new_resource.mount_folder != nil
    
    folder = @new_resource.mount_folder
    
    directory "/mnt/uploads/#{folder}" do
      mode "0755"
      owner "root"
      group "root"
      action :create
      recursive true
    end
    
    bucket = @new_resource.bucket_name
    
    bash "mount s3 bucket on folder" do
      code <<-EOH
      sudo bash -c 'export AWSACCESSKEYID=#{ node[:access_key] }; export AWSSECRETACCESSKEY=#{ node[:secret_key] }; s3fs #{bucket} /mnt/uploads/#{folder} -o allow_other'
      EOH
    
## a instrucao not_if parece nao funcionar devidamente  quando chamada varias vezes seguidas num loop      
      not_if { ::File.directory?("/mnt/uploads/#{folder}/mysql/") }
    end
  end


end
