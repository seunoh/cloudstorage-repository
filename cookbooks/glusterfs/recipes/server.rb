package "glusterfs-server" do
	action :install
end


directory node[:glusterfs][:server][:export_directory] do
  recursive true
end


service "glusterd" do
  action :start
end


# build peers
if node[:glusterfs][:server][:peers].index(node['ipaddress']) == 0 then
	node[:glusterfs][:server][:peers].each do |peer|
		# peer 추가
		execute "gluster peer probe #{peer}" do
			not_if "gluster peer status | grep '^Hostname: #{peer}'" 
			not_if { peer == node['ipaddress'] }
		end
	
		#peer brick add
		node[:glusterfs][:server][:volumes][:name][0].each do |volume|
			execute "gluster volume add-brick #{volume} #{peer}:/#{volume}" do
				not_if "gluster volume info #{volume} | grep '#{peer}:/#{volume}$'"
				only_if "gluster volume info | grep -c '^Volume Name: #{volume}'$"
				only_if "gluster volume info #{volume} | grep 'Status: Started'"
			end
		end
	end
end

service "glusterfs-server" do
	action :restart
end

#is_volume_node = node[:glusterfs][:server][:volume].index(node['ipaddress']) == 0
# volume create & starts
node[:glusterfs][:server][:volumes][:name][0].each do |volume|
	peers = `gluster peer status | grep ^Hostname | awk '{print $2}'`.split.map{|x| "#{x}:/#{volume}"}.join(' ')

	execute "gluster volume create #{volume} replica 2 #{peers}" do
		not_if "gluster volume info | grep -c '^Volume Name: #{volume}'$"
	end

	execute "gluster volume start #{volume}" do
		not_if "gluster volume info #{volume} | grep 'Status: Started'"
	end
end

