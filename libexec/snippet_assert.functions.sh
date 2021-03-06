##/bin/bash
## Provides function assert() and friends.
## 

[ -z "$assert_functions_p" ] || return 0

assert_functions_p=t

assert_debug_p=

##

xx_lod_for_assertions=9

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

	local xc=0 ; xx_lod "${xx_lod_for_assertions:?}" "${command:?}" "${command_args[@]}" || xc=$?

	if [[ ${xc:?} -ne ${expected_xc:?} ]] ; then

		echo 1>&2
		echo 1>&2 "${this_script_name:?}: unexpected exit code: ${xc:?}; expected: ${expected_xc:?}"
		echo 1>&2 "$(assertion_call_stack)"

		return 1
	fi

	return 0
}

function assertion_call_stack() { #

	local i
	local call_frame_count=0
	local call_frame_count_max=5

	for ((i = 2; i < ${#FUNCNAME[@]}; i++)) ; do

		local line_in_caller=${BASH_LINENO[$(($i - 1))]}

		[[ $((call_frame_count ++)) -lt ${call_frame_count_max} ]] || break

		echo "^-- at line ${line_in_caller:?}; function ${FUNCNAME[$i]:?}; file ${BASH_SOURCE[$i]:?}"
	done
}
