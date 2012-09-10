package "glusterfs-server" do
	action :install
end


directory node[:glusterfs][:server][:export_directory] do
  recursive true
end

service "glusterd" do
  action :start
end
