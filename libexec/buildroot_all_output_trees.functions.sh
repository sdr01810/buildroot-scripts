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

function resolve_buildroot_defconfig_for() { # output_selector defconfig_fbn [ defconfig_fbn_hint ]

	local output_selector=${1:?missing value for output_selector} ; shift 1

	local defconfig_fbn=${1:?missing value for defconfig_fbn} ; shift 1

	if [[ ${defconfig_fbn:?} =~ ^(:skip:${output_selector:?})$ ]] ; then

		return 0
	fi

	local result=

	local defconfig_fbn_hint=${1} ; shift 1 || :

	if [[ ${defconfig_fbn:?} =~ ^(:infer:${output_selector:?})$ ]] ; then

		result=$(basename "${defconfig_fbn_hint:-${BR2_DEFCONFIG:-${BR2_ENV_DEFCONFIG:-}}")

		result=${result/main_defconfig/${output_selector:?}_defconfig}
		result=${result/xctc_defconfig/${output_selector:?}_defconfig}

		if [[ ${output_selector} == xctc ]] ; then

			# accept inference only if selected build output already exists

			eval local selected_build_output_dpn=\${BR2_ENV_OUTPUT_${output_selector^^?}_DIR}

			if ! [[ -n ${selected_build_output_dpn} && -d ${selected_build_output_dpn} ]] ; then 

				result=
			fi
		fi
	else
		result=$(basename "${defconfig_fbn:?}")
	fi

	check_looks_like_buildroot_defconfig_for "${output_selector:?}" "${result:?}" || return $?

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

		xx_buildroot_all_output_trees_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"xx_buildroot_all_output_trees_${action:?}" "${action_args[@]}"
	fi
}

function buildroot_all_output_trees_build() { # [ main_defconfig_fbn [ xctc_defconfig_fbn ] ]

	local main_defconfig_fbn= xctc_defconfig_fbn=

	if [[ ${#} -ge 1 ]] ; then

		main_defconfig_fbn=${1:-:infer:main} ; shift 1

		main_defconfig_fbn=$(resolve_buildroot_main_defconfig "${main_defconfig_fbn:?}")
	fi

	if [[ ${#} -ge 1 ]] ; then

		xctc_defconfig_fbn=${1:-:infer:xctc} ; shift 1

		xctc_defconfig_fbn=$(resolve_buildroot_xctc_defconfig "${xctc_defconfig_fbn:?}" "${main_defconfig_fbn}")
	fi

	local output_selectors=()
	local output_selector

	! [[ -n ${xctc_defconfig_fbn} ]] || output_selectors+=( xctc )

	! [[ -n ${main_defconfig_fbn} ]] || output_selectors+=( rol main )

	for output_selector in "${output_selectors[@]}" ; do

		local output_tree_goal= output_tree_goals=()

		if [[ "${output_selector:?}" == xctc ]] ; then
					
			output_tree_goals+=( "${xctc_defconfig_fbn:?}" )
		else
			output_tree_goals+=( "${main_defconfig_fbn:?}" )
		fi

		output_tree_goals+=( update-defconfig all )

		for output_tree_goal in "${output_tree_goals[@]}" ; do

			if [[ ${output_tree_goal} == all || ${output_selector} =~ ^(xctc|main)$ ]] ; then

				xx :

				xx buildroot.sh --output-"${output_selector:?}" "${output_tree_goal:?}"
			fi
		done
	done
}

function buildroot_all_output_trees_clean() { #

	local output_selector

	for output_selector in xctc rol main ; do

		xx :

		xx buildroot.sh --output-"${output_selector:?}" clean
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
