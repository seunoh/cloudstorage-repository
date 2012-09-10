#
# Cookbook Name:: gluster
# Recipe:: brick
#
# Copyright 2012, sw maestro
#
# All rights reserved - Do Not Redistribute
#

package "glusterfs-server" do
  action :install
end

directory node[:glusterfs][:server][:export_directory] do
  recursive true
end

service "glusterd" do
  action :start
end
