##/bin/bash
## Provides function buildroot_all_output_trees() and friends.
## 

[ -z "$buildroot_all_output_trees_functions_p" ] || return 0

buildroot_all_output_trees_functions_p=t

buildroot_all_output_trees_debug_p=

##

source buildroot_config.functions.sh

##

function check_looks_like_buildroot_defconfig_for() { # output_selector defconfig_fbn

	local output_selector="${1:?missing value for output_selector}" ; shift 1

	local defconfig_fbn="${1:?missing value for defconfig_fbn}" ; shift 1

	case "${defconfig_fbn:?}" in
	/*|*/*|*/)

		echo 1>&2 "${this_script_fbn:?}: incorrect ${output_selector:?} defconfig name (cannot be a pathname): ${defconfig_fbn:?}"
		false
		;;

	*_"${output_selector:?}_defconfig"|"${output_selector:?}_defconfig")

		true
		;;

	*)
		echo 1>&2 "${this_script_fbn:?}: incorrect ${output_selector:?} defconfig name (must end with '_${output_selector:?}_defconfig'): ${defconfig_fbn:?}"
		false
		;;
	esac
}

function check_looks_like_buildroot_main_defconfig() { # main_defconfig_fbn

	check_looks_like_buildroot_defconfig_for main "$@"
}

function check_looks_like_buildroot_xctc_defconfig() { # xctc_defconfig_fbn

	check_looks_like_buildroot_defconfig_for xctc "$@"
}

function buildroot_all_output_trees() { # ...

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

	load_buildroot_config

        if [[ -n ${clean_all_p} ]] ; then

		xx_buildroot_all_output_trees_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"xx_buildroot_all_output_trees_${action:?}" "${action_args[@]}"
	fi
}

function buildroot_all_output_trees_build() { # xctc_defconfig_fbn main_defconfig_fpn

	local xctc_defconfig_fbn="${1:?missing value for xctc_defconfig_fbn}" ; shift 1

	local main_defconfig_fbn="${1:?missing value for main_defconfig_fbn}" ; shift 1

	check_looks_like_buildroot_xctc_defconfig "${xctc_defconfig_fbn:?}" || return $?

	check_looks_like_buildroot_main_defconfig "${main_defconfig_fbn:?}" || return $?

	xx :

	xx buildroot.sh --output-xctc "${xctc_defconfig_fbn:?}"

	xx :

	xx buildroot.sh --output-xctc update-defconfig

	xx :

	xx buildroot.sh --output-main "${main_defconfig_fbn:?}"

	xx :

	xx buildroot.sh --output-main update-defconfig

	##

	local output_tree_type

	for output_tree_type in xctc rol main ; do

		xx :

		xx buildroot.sh --output-"${output_tree_type:?}" all
	done
}

function buildroot_all_output_trees_clean() { #

	local output_tree_type

	for output_tree_type in xctc rol main ; do

		xx :

		xx buildroot.sh --output-"${output_tree_type:?}" clean
	done
}

function xx_buildroot_all_output_trees() { # ...

	buildroot_all_output_trees "$@"
}

function xx_buildroot_all_output_trees_build() { # ...

	buildroot_all_output_trees_build "$@"
}

function xx_buildroot_all_output_trees_clean() { # ...

	buildroot_all_output_trees_clean "$@"
}
