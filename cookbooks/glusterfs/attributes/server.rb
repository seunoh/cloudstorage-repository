default[:glusterfs][:server][:export_directory] = "/export/glusterfs"

default[:glusterfs][:server][:volume] ="192.168.37.123"

default[:glusterfs][:server][:peers] = [
	"192.168.37.121",
	"192.168.37.122",
	"192.168.37.123",
]

default[:glusterfs][:server][:volumes][:name] = [
	"glusterfs1",
	"glusterfs2",
]
