#
# Cookbook Name:: swap
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

swap_size_megs = (node['create-swap']['swap-size'] * 1024)

# Create our swapfile with dd
# Set the permissions to 600
# And mkswap it (mkswap sets up a Linux swap area on a device or in a file)

execute 'create swapfile' do
  command <<-EOF.gsub(/^\s{4}/, '')
    dd if=/dev/zero of=#{node['create-swap']['swap-location']} bs=1M count=#{swap_size_megs}
    chmod 600 #{node['create-swap']['swap-location']}
    mkswap #{node['create-swap']['swap-location']}
  EOF

  not_if { ::File.exists? node['create-swap']['swap-location'] }
end

# Add a mount entry to fstab which resembles the following:
# /var/swapfile none swap sw 0 0
# This will cause the swapfile to persist across reboots

mount 'none' do
  action :enable
  device node['create-swap']['swap-location']
  fstype 'swap'
end

# All devices marked as ``swap'' in /etc/fstab are made available,
# except for those with the ``noauto'' option.  Devices that are already
# being used as swap are silently skipped, so we don't need a guard.

execute 'activate swap' do
  command 'swapon -a'
end
