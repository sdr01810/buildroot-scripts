#!/bin/bash sourced
## 
## Arguments:
## 
##     [ module ... ]
## 
## Typical uses:
## 
##     buildroot_api
##     buildroot_api ""
##     
##     buildroot_api event_handling
## 

[ -z "$buildroot_cli_handler_for_api_functions_p" ] || return 0

buildroot_cli_handler_for_api_functions_p=t

buildroot_cli_handler_for_api_debug_p=

##

source buildroot_api.functions.sh

##

function buildroot_cli_handler_for_api() { # ...

	buildroot_api "$@"
}

