#!/bin/bash sourced
## Install the latest stable buildroot and associated tools.
## 
## Arguments:
##
##     [ --dependencies-only | [--everything] ]
## 
## Typical uses:
##
##     buildroot_install
##     buildroot_install --everything
##     
##     buildroot_install --dependencies-only
##

[ -z "$buildroot_cli_handler_for_install_functions_p" ] || return 0

buildroot_cli_handler_for_install_functions_p=t

buildroot_cli_handler_for_install_debug_p=

##

source buildroot_api_install.functions.sh

##

function buildroot_cli_handler_for_install() { # ...

	buildroot_install "$@"
}

