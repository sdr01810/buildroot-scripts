##/bin/bash
## Provides function buildroot_target_tree() and friends.
## 

[ -z "$buildroot_target_tree_functions_p" ] || return 0

buildroot_target_tree_functions_p=t

buildroot_target_tree_debug_p=

##

source buildroot_api_config.functions.sh
source buildroot_api_make.functions.sh

##

function buildroot_target_tree() { # ...

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
	        break
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

		buildroot_target_tree_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"buildroot_target_tree_${action:?}" "${action_args[@]}"
	fi
}

function buildroot_target_tree_build() { #

	buildroot_make O="${BR2_ENV_OUTPUT_DIR:?}" skeleton all
}

function buildroot_target_tree_clean() { #

	xx rm -rf "${BR2_ENV_OUTPUT_DIR:?}"/target 

	buildroot_make O="${BR2_ENV_OUTPUT_DIR:?}" skeleton-dirclean

	find -H "${BR2_ENV_OUTPUT_DIR:?}"/build -name '.stamp_target_installed' |
	while read -r x1 ; do xx rm -rf "${x1:?}" ; done
}

