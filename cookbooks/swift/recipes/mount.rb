#
# Cookbook Name:: swift
# Recipe:: mount
#
# Copyright 2012, sw maestro
#
# All rights reserved - Do Not Redistribute
#

%w{xfsprogs}.each do |pkg|
  package pkg
end

directory "/srv" do
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0755"
  recursive true
end

execute "build swiftfs" do
  command "dd if=/dev/zero of=/srv/swift-disk bs=1024 count=0 seek=1000000"
  not_if { File.exists?("/srv/swift-disk") }
end

execute "associate loopback" do
  command "losetup /dev/loop0 /srv/swift-disk"
  not_if { `losetup /dev/loop0` =~ /swift-disk/ }
end

execute "build filesystem" do
  command "mkfs.xfs -i size=1024 /dev/loop0"
  not_if 'xfs_admin -u /dev/loop0'
end

directory "/mnt/sdb1" do
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0755"
end

execute "update fstab" do
  command "echo '/dev/loop0 /mnt/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab"
  not_if "grep '/dev/loop0' /etc/fstab"
end

execute "mount /mnt/sdb1" do
  not_if "df | grep /dev/loop0"
end
