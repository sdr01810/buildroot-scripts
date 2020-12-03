##/bin/bash
## Provides utility functions for working with tests written as shell scripts.
## 

[ -z "$test_functions_p" ] || return 0

test_functions_p=t

test_debug_p=

##

function expect_xc() { # expected_exit_code command [command_arg ...]

	local expected_xc="${1:?missing value for expected_exit_code}" ; shift 1

	local command="${1:?missing value for command}" ; shift 1

	local command_args=( "$@" ) ; shift $#

	[ $# -eq 0 ]

	local xc=0

	( xx : ; xx "${command:?}" "${command_args[@]}" ) 1>&2 || xc=$?

	if [ "${xc:?}" -ne "${expected_xc:?}" ] ; then

		echo 1>&2 "^-- unexpected exit code: ${xc:?}; expected: ${expected_xc:?}"
		return 1
	fi

	return 0
}
