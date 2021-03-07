#!/bin/bash
## Buildroot package event handling script.
##
## Arguments:
##
##     edge_name step_name package_name
##
## Environment:
##
##     The usual pkg-generic variables: BINARIES_DIR, TARGET_DIR, etc.
##
## Typical uses:
##
##     buildroot-hook.package-event.sh start install-target glibc
##
## See also:
##
##     <http://buildroot.net/downloads/manual/manual.html#debugging-buildroot>
##

source "$(dirname "$0")"/buildroot-hook.prolog.sh

if command -v buildroot >/dev/null ; then

	source "$(buildroot api event_handling)"
else
	function handle_raw_buildroot_event_of_type() { # ...

		: # stub
	}
fi

##
## core logic:
##

function main() { # edge_name step_name package_name

	handle_raw_buildroot_event_of_type package "$@"
}

! [[ ${0} == ${BASH_SOURCE} ]] || main "$@"

