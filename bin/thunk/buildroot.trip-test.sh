#!/bin/bash
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
##     buildroot.trip-test.sh
##     buildroot.trip-test.sh --run
##     
##     buildroot.trip-test.sh --clean-only
##     buildroot.trip-test.sh --clean-first
## 

source "$(dirname "${BASH_SOURCE:?}")"/../../libexec/buildroot_cli.prolog.sh

source buildroot_api_trip_test.functions.sh

##

function main() { # ...

	xx_buildroot_trip_test "$@"
}

! [ "$0" = "${BASH_SOURCE}" ] || main "$@"
