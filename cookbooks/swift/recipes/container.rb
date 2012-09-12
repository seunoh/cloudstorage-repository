#
# Cookbook Name:: swift
# Recipe:: container
#
# Copyright 2012, sw maestro
#
# All rights reserved - Do Not Redistribute
#

include_recipe "swift::default"
include_recipe "swift::xfs"

App="container"

package "swift-#{App}" do
  action :install
end

template "/etc/rsyncd.conf" do
  source "rsyncd.conf.erb"
  owner node[:storage][:user]
  group node[:storage][:group]
  variables (
    { :content_name => App }
  )
end

cookbook_file "/etc/default/rsync" do
  source "default-rsync"
end

service "rsync" do
  action :start
end

template "/etc/swift/#{App}-server.conf" do
  source "#{App}-server.conf.erb"
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0755"
end

passwd = "#{node[:storage][:proxy][:passwd]}"
user = "#{node[:storage][:proxy][:user]}"
ip = "#{node[:storage][:proxy][:ip]}"

execute "ring copy" do
  command "sshpass -p #{passwd} scp -oStrictHostKeyChecking=no #{user}@#{ip}:/etc/swift/*.ring.gz /etc/swift"
  cwd "/etc/swift"
end

execute "swift-init #{App}-server start" do
end

execute "swift-init #{App}-replicator start" do
end

execute "swift-init #{App}-updater start" do
end

execute "swift-init #{App}-auditor start" do
end
