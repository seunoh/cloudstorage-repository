#
# Cookbook Name:: swift
# Recipe:: single
#
# Copyright 2012, sw maestro
#
# All rights reserved - Do Not Redistribute
#

%w{curl gcc git-core memcached python-configobj python-coverage python-dev python-nose python-setuptools python-simplejson python-xattr sqlite3 xfsprogs python-webob python-eventlet python-greenlet python-pastedeploy python-netifaces}.each do |pkg_name|
  package pkg_name
end

directory "/srv" do
  owner node[:storage][:user] 
  group node[:storage][:group] 
  mode "0644"
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
  mode "0644"
end

execute "update fstab" do
  command "echo '/dev/loop0 /mnt/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab"
  not_if "grep '/dev/loop0' /etc/fstab"
end

execute "mount /mnt/sdb1" do
  not_if "df | grep /dev/loop0"
end

%w{1 2 3 4}.each do |swift_dir|
  directory "/mnt/sdb1/#{swift_dir}" do
    owner node[:storage][:user] 
    group node[:storage][:group] 
    mode "0644"
  end

  link "/tmp/#{swift_dir}" do
    to "/mnt/sdb1/#{swift_dir}"
  end

  link "/srv/#{swift_dir}" do
    to "/mnt/sdb1/#{swift_dir}"
  end
end

directory "/etc/swift" do
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0644"
end

%w{1 2 3 4}.each do |swift_dir|
  directory "/srv/#{swift_dir}/node/sdb/#{swift_dir}" do
    owner node[:storage][:user]
    group node[:storage][:group]
    mode "0644"
    recursive true
  end
end
	
%w{/etc/swift/object-server /etc/swift/container-server /etc/swift/account-server /var/run/swift}.each do |new_dir|
  directory new_dir do
    owner node[:storage][:user]
    group node[:storage][:group]
    recursive true
    mode "0644"
  end
end

template "/etc/rc.local" do
  source "single-rc.local.erb"
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0644"
end

template "/etc/rsyncd.conf" do
  source "single-rsyncd.conf.erb"
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0644"
end

cookbook_file "/etc/default/rsync" do
  source "default-rsync"
end

service "rsync" do
  action :start
end

template "/etc/rsyslog.d/10-swift.conf" do
  source "single-10-swift.conf.erb"
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0644"
end

directory "/var/log/swifti/hourly" do
  owner "#{node[:storage][:user]}"
  group "#{node[:storage][:group]}"
  mode "0644"
  recursive true
end

service "rsyslog" do
  action :restart
end

directory "#{node[:storage][:homedir]}/bin" do
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0644"
end

git "#{node[:storage][:homedir]}/swift" do
  repository "https://github.com/openstack/swift.git"
  destination "#{node[:storage][:homedir]}/swift"
end

execute "python setup.py develop" do
  cwd "#{node[:storage][:homedir]}/swift"
end

git "#{node[:storage][:homedir]}/python-swiftclient" do
  repository "https://github.com/openstack/python-swiftclient.git"
  destination "#{node[:storage][:homedir]}/python-swiftclient"
end

execute "python setup.py develop" do
  cwd "#{node[:storage][:homedir]}/python-swiftclient"
end

ENV["PYTHONPATH"] = "#{node[:storage][:homedir]}/swift"
ENV["SWIFT_TEST_CONFIG_FILE"] = '/etc/swift/test.conf'
ENV["PATH"] += ":~/bin"

[ 
  'export PYTHONPATH=~/swift',
  'export SWIFT_TEST_CONFIG_FILE=/etc/swift/test.conf',
  'export PATH=${PATH}:~/bin' 
].each do |bash_bit|
  execute "echo '#{bash_bit}' >> ~/.bashrc; . ~/.bashrc" do
    not_if "grep '#{bash_bit}' ~/.bashrc"
  end
end

template "/etc/swift/proxy-server.conf" do
  source "single-proxy-server.conf.erb"
  mode "0644"
  owner node[:storage][:user]
  group node[:storage][:group]
end

template "/etc/swift/swift.conf" do
  source "single-swift.conf.erb"
  mode "0644"
  owner node[:storage][:user]
  group node[:storage][:group]
end

%w{1 2 3 4}.each do |server_num|
  %w{account container object}.each do |server_type|
    template "/etc/swift/single-#{server_type}-server/#{server_num}.conf" do
      variables({ :server_num => server_num })
      source "#{server_type}-server-conf.erb"
      mode "0644"
      owner node[:storage][:user]
      group node[:storage][:group]
    end
  end
end

%w{resetswift remakerings startmain startrest}.each do |bin_file|
  template "#{node[:storage][:homedir]}/bin/#{bin_file}" do
    source "#{bin_file}.erb"
    owner node[:storage][:user]
    group node[:storage][:group]
    mode "0755"
  end
end

template "/etc/swift/test.conf" do
  source "single-sample.conf.erb"
  owner node[:storage][:user]
  group node[:storage][:group]
  mode "0644"
end

execute "remakerings" do
  not_if { File.exists?("~/bin/remakerings") }
end

execute "startmain" do
  not_if { File.exists?("~/bin/startmain") }
end

execute "storage and auth token" do
  command "curl -v -H 'X-Storage-User: test:tester' -H 'X-Storage-Pass: testing' http://127.0.0.1:8080/auth/v1.0"
end

execute "test swift" do
  command "swift -A http://127.0.0.1:8080/auth/v1.0 -U test:tester -K testing stat"
end
