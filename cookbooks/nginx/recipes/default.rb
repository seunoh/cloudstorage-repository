#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


package "nginx-full" do
  action :install
end

execute "ldconfig" do
end


service "nginx" do
  action :start
end

