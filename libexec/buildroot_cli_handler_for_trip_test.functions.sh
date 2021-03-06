#!/bin/bash sourced
## Puts this family of commands through its paces, trying to make it fall over.
## 
## Arguments:
##
##     --clean-only 
##     
##     [ --run ] [ --clean-first ] [ starting_state ]
## 
## Typical uses:
##
##     buildroot_trip_test
##     buildroot_trip_test --run
##     
##     buildroot_trip_test --clean-only
##     buildroot_trip_test --clean-first
## 

[ -z "$buildroot_cli_handler_for_trip_test_functions_p" ] || return 0

buildroot_cli_handler_for_trip_test_functions_p=t

buildroot_cli_handler_for_trip_test_debug_p=

##

source buildroot_api_trip_test.functions.sh

##

function buildroot_cli_handler_for_trip_test() { # ...

	xx_buildroot_trip_test "$@"
}

