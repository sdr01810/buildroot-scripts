#!/bin/bash sourced
## Invoke make(1) for a buildroot-based build.
## 
## Arguments:
## 
##     [ <any-make-arg> ... ]
## 
## Typical uses:
##
##     buildroot_make
##     buildroot_make all
##     
##     buildroot_make clean
## 

[ -z "$buildroot_cli_handler_for_make_functions_p" ] || return 0

buildroot_cli_handler_for_make_functions_p=t

buildroot_cli_handler_for_make_debug_p=

##

source buildroot_api_make.functions.sh

##

function buildroot_cli_handler_for_make() { # ...

	load_buildroot_config

	buildroot_make "$@"
}

