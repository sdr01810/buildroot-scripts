##/bin/bash
## Provides function assert() and friends.
## 

[ -z "$assert_functions_p" ] || return 0

assert_functions_p=t

assert_debug_p=

##

function assert() { # command [command_arg ...]

	assert_that "$@"
}

function assert_test() { # test_arg ...

	assert_that test "$@"
}

function assert_that() { # command [command_arg ...]

	local command="${1:?missing value for command}" ; shift 1

	local command_args=( "$@" ) ; shift $#

	local expected_xc=0 xc=

	( "${command:?}" "${command_args[@]}" ) 1>&2 && xc=$? || xc=$?

	if [ "${xc:?}" -ne "${expected_xc:?}" ] ; then

		echo 1>&2 "^-- assertion failed (exit code ${xc:?}): ${command:?} ${command_args[0]}"
		return 1
	fi

	return 0
}
