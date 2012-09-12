#
# Role Name:: swift-proxy
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

name "swift-proxy"
description "provides the proxy and authentication components to swift"
run_list(
    "recipe[swift::default]",
    "recipe[swift::proxy]"
)

#override_attributes "swift" => { "account_management" => "false" }
