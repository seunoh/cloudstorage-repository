#
# Cookbook Name:: swift
# Recipe:: mountmonitor
#
# Copyright 2012, sw maestro
#
# All rights reserved - Do Not Redistribute
#


template "/usr/local/bin/swift-mountmonitor" do
  source "swift.monitor.mounts.erb"
  mode "0755"
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
end

cron "swift_mount_monitor" do
  minute "*/15"
  command "/usr/local/bin/swift-mountmonitor"
end
