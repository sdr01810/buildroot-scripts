#!/bin/bash sourced
## Provides default implementation of buildroot-specific test condition handlers.
##

[ -z "$buildroot_api_test_impl_functions_p" ] || return 0

buildroot_api_test_impl_functions_p=t

buildroot_api_test_impl_debug_p=

##

function test_buildroot_condition__handler_for_condition_of_type_any__impl_default() { # caller_function_name [ expected_state_spec ... ]

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	local expected_state_spec

	for expected_state_spec in "$@" ; do

		"${FUNCNAME:?}"_1 "${caller_function_name:?}" "${expected_state_spec}"
	done
}

function test_buildroot_condition__handler_for_condition_of_type_any__impl_default_1() { # caller_function_name [ expected_state_spec ]

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	local expected_state_spec=${1} ; shift 1 || :

	local expected_state_type expected_state_value

	case "${expected_state_spec}" in
	*)
		case "${expected_state_spec:?}" in
		*:*)
			expected_state_type=${expected_state_spec%%:*}
			expected_state_value=${expected_state_spec#*:}
			;;
		*)
			expected_state_type=exists
			expected_state_value=${expected_state_spec}
			;;
		esac

		(
			local handler=${caller_function_name:?}__handler_for_expected_state_of_type_${expected_state_type//-/_}

			if ! [[ $(type -t "${handler:?}") == function ]] ; then

				echo 1>&2 "${FUNCNAME:?}: unrecognized expected state type: ${expected_state_type:?}"
				list_call_stack 1>&2
				return 2
			fi

			"${handler:?}" "${expected_state_value}"
		)
		;;

	'')
		echo 1>&2 "${FUNCNAME:?}: empty expected state spec"
		list_call_stack 1>&2
		return 2
		;;
	esac
}

