#!/bin/bash sourced
## Provides functions that test buildroot-specific conditions.
##

[ -z "$buildroot_api_test_functions_p" ] || return 0

buildroot_api_test_functions_p=t

buildroot_api_test_debug_p=

##

source "${BASH_SOURCE%.*.sh}".impl.functions.sh

source buildroot_api_xctc_sdk_depot.functions.sh

source snippet_list_call_stack.functions.sh

##

function test_buildroot_condition() { # [ condition_spec ... ]

	local condition_spec

	for condition_spec in "$@" ; do

		"${FUNCNAME:?}"_1 "${condition_spec}"
	done
}

function test_buildroot_condition_1() { # [ condition_spec ]

	local condition_spec=${1} ; shift 1 || :

	local condition_type expected_state_specs=()

	local x x_list_remaining

	case "${condition_spec,,?}" in
	*:*)
		condition_type=${condition_spec%%:*}

		x_list_remaining=${condition_spec#*:}

		while [[ -n ${x_list_remaining} ]] ; do

			x=${x_list_remaining%%,*}

			expected_state_specs+=( "${x}" )

			x_list_remaining=${x_list_remaining#*,}
			! [[ ${x_list_remaining} == ${x} ]] || x_list_remaining=
		done

		"${FUNCNAME%_1}"__handler_for_condition_of_type \
			"${condition_type:?}" "${expected_state_specs[@]}"

		return
		;;

	*)
		echo 1>&2 "${FUNCNAME:?}: invalid condition spec: ${condition_spec:?}"

		list_call_stack 1>&2

		return 2
		;;

	'')
		echo 1>&2 "${FUNCNAME:?}: empty condition spec"

		list_call_stack 1>&2

		return 2
		;;
	esac
}

function test_buildroot_condition__handler_for_condition_of_type() { # condition_type [ expected_state_spec ... ]

	local condition_type=${1:?missing value for condition_type} ; shift 1

	local delegate=${FUNCNAME:?}_${condition_type//-/_}

	if ! [[ $(type -t "${delegate:?}") == function ]] ; then

		echo 1>&2 "${FUNCNAME:?}: unrecognized condition type: ${condition_type:?}"
		list_call_stack 1>&2
		return 2
	fi

	"${delegate:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_dl_ptb() { # [ expected_state_spec ... ]

	"${FUNCNAME/%_dl_ptb/_any}"__impl_default "${FUNCNAME:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_dl_rol() { # [ expected_state_spec ... ]

	"${FUNCNAME/%_dl_rol/_any}"__impl_default "${FUNCNAME:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_main() { # [ expected_state_spec ... ]

	"${FUNCNAME/%_main/_any}"__impl_default "${FUNCNAME:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_rol() { # [ expected_state_spec ... ]

	"${FUNCNAME/%_rol/_any}"__impl_default "${FUNCNAME:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_xctc() { # [ expected_state_spec ... ]

	"${FUNCNAME/%_xctc/_any}"__impl_default "${FUNCNAME:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_xctc_sdk() { # [ expected_state_spec ... ]

	"${FUNCNAME/%_xctc_sdk/_any}"__impl_default "${FUNCNAME:?}" "$@"
}

function test_buildroot_condition__handler_for_condition_of_type_dl_ptb__handler_for_expected_state_of_type_exists() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -d "${BR2_ENV_DL_PTB_DIR:?}"
}

function test_buildroot_condition__handler_for_condition_of_type_dl_rol__handler_for_expected_state_of_type_exists() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -d "${BR2_ENV_DL_ROL_DIR:?}"
}

function test_buildroot_condition__handler_for_condition_of_type_main__handler_for_expected_state_of_type_exists() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -d "${BR2_ENV_OUTPUT_MAIN_DIR:?}"
}

function test_buildroot_condition__handler_for_condition_of_type_main__handler_for_expected_state_of_type_rootfs() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -s "${BR2_ENV_OUTPUT_MAIN_DIR:?}"/images/rootfs.cpio
}

function test_buildroot_condition__handler_for_condition_of_type_rol__handler_for_expected_state_of_type_exists() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -d "${BR2_ENV_OUTPUT_ROL_DIR:?}"
}

function test_buildroot_condition__handler_for_condition_of_type_rol__handler_for_expected_state_of_type_debootstrap() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -d "${BR2_ENV_OUTPUT_ROL_DIR:?}"/debootstrap
}

function test_buildroot_condition__handler_for_condition_of_type_rol__handler_for_expected_state_of_type_tarball() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -s "${BR2_ENV_OUTPUT_ROL_DIR:?}".tar
}

function test_buildroot_condition__handler_for_condition_of_type_xctc__handler_for_expected_state_of_type_exists() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" -d "${BR2_ENV_OUTPUT_XCTC_DIR:?}"
}

function test_buildroot_condition__handler_for_condition_of_type_xctc_sdk__handler_for_expected_state_of_type_exists() { # [ expected_state_value ]

	local expected_state_value=${1:-yes} ; shift 1 || :

	local tb_count

	tb_count=$(get_buildroot_xctc_sdk_tarball --image --pa --dl | wc -l)

	case "${expected_state_value:?}" in
	n|no)
		test_buildroot_condition_predicate_with_expected_state_value \ 
			"${expected_state_value:?}" "${tb_count:?}" -eq 0
		return
		;;

	*)
		test_buildroot_condition_predicate_with_expected_state_value \ 
			"${expected_state_value:?}" "${tb_count:?}" -eq 3
		return
		;;
	esac
}

function test_buildroot_condition__handler_for_condition_of_type_xctc_sdk__handler_for_expected_state_of_type_image() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" 1 -eq "$(get_buildroot_xctc_sdk_tarball --image | wc -l)"
}

function test_buildroot_condition__handler_for_condition_of_type_xctc_sdk__handler_for_expected_state_of_type_pa() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" 1 -eq "$(get_buildroot_xctc_sdk_tarball --pa | wc -l)"
}

function test_buildroot_condition__handler_for_condition_of_type_xctc_sdk__handler_for_expected_state_of_type_dl() { # [ expected_state_value ]

	test_buildroot_condition_predicate_with_expected_state_value "${1}" 1 -eq "$(get_buildroot_xctc_sdk_tarball --dl | wc -l)"
}

function test_buildroot_condition_predicate_with_expected_state_value() { # expected_state_value [ predicate_term ... ]

	local expected_state_value=${1:-yes} ; shift 1 || :

	local predicate_rc=0 ; [ "$@" ] || predicate_rc=$?

	case "${expected_state_value,,?}" in
	\?)
		true
		return
		;;

	y|yes)
		[[ ${predicate_rc:?} -eq 0 ]]
		return
		;;

	n|no)
		[[ ${predicate_rc:?} -ne 0 ]]
		return
		;;

	[0-9]*)
		[[ ${predicate_rc:?} -eq ${expected_state_value:?} ]]
		return
		;;

	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized expected state value: ${expected_state_value:?}"
		return 2
		;;

	'')
		echo 1>&2 "${FUNCNAME:?}: empty expected state value"
		return 2
		;;
	esac
}

