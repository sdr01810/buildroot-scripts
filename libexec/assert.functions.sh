##/bin/bash
## Provides function assert() and friends.
## 

[ -z "$assert_functions_p" ] || return 0

assert_functions_p=t

assert_debug_p=

##

function assert() { # command [command_arg ...]

	assert_xc 0 "$@"
}

function assert_test() { # test_arg ...

	assert_xc 0 test "$@"
}

function assert_that() { # command [command_arg ...]

	assert_xc 0 "$@"
}

function assert_xc() { # expected_exit_code command [command_arg ...]

	local expected_xc="${1:?missing value for expected_exit_code}" ; shift 1

	local command="${1:?missing value for command}" ; shift 1

	local command_args=( "$@" ) ; shift $#

	[ $# -eq 0 ] || return 2

	local xc=

	xx_lod_assert "${command:?}" "${command_args[@]}" && xc=$? || xc=$?

	if [ "${xc:?}" -ne "${expected_xc:?}" ] ; then

		echo 1>&2 "^-- unexpected exit code: ${xc:?}; expected: ${expected_xc:?}"
		return 1
	fi

	return 0
}

function xx_lod_assert() { # ...

	xx_lod 9 "$@"
}

