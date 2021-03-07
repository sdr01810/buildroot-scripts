#!/bin/bash sourced
## Provides function buildroot_all_output_trees() and friends.
##

[ -z "$buildroot_all_output_trees_functions_p" ] || return 0

buildroot_all_output_trees_functions_p=t

buildroot_all_output_trees_debug_p=

##

source buildroot_api_config.functions.sh

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

function best_defconfig_fbn_hint_for() {( # output_selector [ defconfig_fbn_hint ]

	local output_selector=${1:?missing value for output_selector} ; shift 1

	local defconfig_fbn_hint=${1} ; shift 1 || :

	local config_file_selectors=()
	local config_file_selector

	case "${output_selector:?}" in
	main)
		config_file_selectors+=( main xctc )
		;;
	xctc)
		config_file_selectors+=( xctc main )
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unrecognized output selector: ${output_selector}"
		return 2
	esac

	local result=

	load_buildroot_config --defaults file-only --output-none

	# don't build the toolchain/sdk implicitly unless you've done so already

	if [[ ${output_selector:?} == xctc && ! -d ${BR2_OUTPUT_XCTC_DIR:?} ]] ; then

		result=:skip:${output_selector:?}
	else
		result=${defconfig_fbn_hint}
	fi

	if ! [[ -n ${result} ]] ; then

		# find the most appropriate buildroot .config file, and rely on that

		for config_file_selector in "${config_file_selectors[@]}" ; do

			load_buildroot_config --defaults file-omit --output-${config_file_selector}

			result=${BR2_DEFCONFIG:-}

			! [[ -n ${result} ]] || break
		done
	fi

	if [[ -n ${result} ]] ; then

		result=$(basename "${result}")

		result=${result/main_defconfig/${output_selector:?}_defconfig}
		result=${result/xctc_defconfig/${output_selector:?}_defconfig}
	fi

	echo "${result}"
)}

function resolve_buildroot_defconfig_for() { # output_selector defconfig_fbn [ defconfig_fbn_hint ]

	local output_selector=${1:?missing value for output_selector} ; shift 1

	local defconfig_fbn=${1:?missing value for defconfig_fbn} ; shift 1

	local defconfig_fbn_hint=${1} ; shift 1 || :

	##

	local result=${defconfig_fbn:?}

	if [[ ${result:?} =~ ^(:infer:${output_selector:?})$ ]] ; then

		result=$(best_defconfig_fbn_hint_for "${output_selector:?}" "${defconfig_fbn_hint}")
	fi

	if [[ ${result} =~ ^(:skip:${output_selector:?})$ ]] ; then

		result=
	fi

	if [[ -n ${result} ]] ; then

		result=$(basename "${result}")

		check_looks_like_buildroot_defconfig_for "${output_selector:?}" "${result:?}" || return $?
	fi

	echo "${result}"
}

function resolve_buildroot_main_defconfig() { # defconfig_fbn [ defconfig_fbn_hint ]

	resolve_buildroot_defconfig_for main "${@}"
}

function resolve_buildroot_xctc_defconfig() { # defconfig_fbn [ defconfig_fbn_hint ]

	resolve_buildroot_defconfig_for xctc "${@}"
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

        if [[ -n ${clean_all_p} ]] ; then

		buildroot_all_output_trees_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"buildroot_all_output_trees_${action:?}" "${action_args[@]}"
	fi
}

function buildroot_all_output_trees_build() { # [ main_defconfig_fbn [ xctc_defconfig_fbn ] ]

	local main_defconfig_fbn= xctc_defconfig_fbn=

	main_defconfig_fbn=${1:-:infer:main} ; shift 1 || :
	main_defconfig_fbn=$(resolve_buildroot_main_defconfig "${main_defconfig_fbn:?}")

	xctc_defconfig_fbn=${1:-:infer:xctc} ; shift 1 || :
	xctc_defconfig_fbn=$(resolve_buildroot_xctc_defconfig "${xctc_defconfig_fbn:?}" "${main_defconfig_fbn}")

	if ! [[ -n ${main_defconfig_fbn} ]] ; then

		echo 1>&2 "${FUNCNAME:?}: cannot determine defconfig for main build"
		return 2
	fi

	local output_selectors=()
	local output_selector

	! [[ -n ${xctc_defconfig_fbn} ]] || output_selectors+=( xctc )

	! [[ -n ${main_defconfig_fbn} ]] || output_selectors+=( rol main )

	local output_goal_templates=( @load-defconfig@ update-defconfig all )
	local output_goal_template=

	for output_goal_template in "${output_goal_templates[@]}" ; do

		for output_selector in "${output_selectors[@]}" ; do

			if [[ ${output_selector:?} == rol && ${output_goal_template:?} =~ defconfig ]] ; then

				continue # nothing to do: by design rol uses main buildroot config
			fi

			local output_goal=${output_goal_template:?}

			if [[ ${output_goal:?} == @load-defconfig@ ]] ; then

				if [[ ${output_selector:?} == xctc ]] ; then

					output_goal=${xctc_defconfig_fbn:?}
				else
					output_goal=${main_defconfig_fbn:?}
				fi
			fi

			xx :

			xx buildroot --output-"${output_selector:?}" "${output_goal:?}"
		done
	done
}

function buildroot_all_output_trees_clean() { #

	local output_selector

	for output_selector in xctc rol main ; do

		xx :

		xx buildroot --output-"${output_selector:?}" clean
	done
}

