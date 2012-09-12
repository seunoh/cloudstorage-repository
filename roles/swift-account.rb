#
# Role Name:: swift-account
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

name "swift-account"
description "provides the proxy and authentication components to swift"
run_list(
    "recipe[swift::default]",
    "recipe[swift::mount]",
    "recipe[swift::account]"
)
