#!/bin/bash sourced
## Provides function buildroot_host_tree() and friends.
## 

[ -z "$buildroot_host_tree_functions_p" ] || return 0

buildroot_host_tree_functions_p=t

buildroot_host_tree_debug_p=

##

source buildroot_api_config.functions.sh
source buildroot_api_make.functions.sh

##

function buildroot_host_tree() { # ...

	local action=
	local action_args=()
	local clean_all_p=

	while [ $# -gt 0 ] ; do
        case "${1}" in
	--build)
		action="${action:-build}"
		[ "${action:?}" = "build" ]

		shift 1
		;;
	--clean-only)
		action="${action:-clean}"
		[ "${action:?}" = "clean" ]

		clean_all_p=t

		shift 1
		;;
	--clean-first)
		action="${action:-build}"
		[ "${action:?}" = "build" ]

		clean_all_p=t

		shift 1
		;;
	--)
		shift 1
		;;
	-*)
		echo 1>&2 "${FUNCNAME:?}: unsupported option: ${1:?}"

		return 2
		;;
	*|'')
		break
		;;
	esac;done

	action="${action:-build}"

	action_args+=( "$@" ) ; shift $#

	##

        if [[ -n ${clean_all_p} ]] ; then

		buildroot_host_tree_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"buildroot_host_tree_${action:?}" "${action_args[@]}"
	fi
}

function buildroot_host_tree_build() { #

	buildroot_make O="${BR2_ENV_OUTPUT_DIR:?}" host-skeleton all
}

function buildroot_host_tree_clean() { #

	xx rm -rf "${BR2_ENV_OUTPUT_DIR:?}"/host 

	buildroot_make O="${BR2_ENV_OUTPUT_DIR:?}" host-skeleton-dirclean

	find -H "${BR2_ENV_OUTPUT_DIR:?}"/build -name '.stamp_host_installed' |
	while read -r x1 ; do xx rm -rf "${x1:?}" ; done
}

