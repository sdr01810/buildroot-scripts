#!/bin/bash sourced
## Provides function buildroot_cli_dispatcher() and friends.
##

[ -z "$buildroot_cli_dispatcher_functions_p" ] || return 0

buildroot_cli_dispatcher_functions_p=t

buildroot_cli_dispatcher_debug_p=

##

for _1_ in "${BASH_SOURCE%_cli_dispatcher.*.sh}"_cli_handler_*.functions.sh ; do

	source "${_1_:?}"
done

source "${BASH_SOURCE%_cli_dispatcher.*.sh}"_api.functions.sh

source snippet_assert.functions.sh

##

function check_buildroot_command() { # actual_value expected_value

	if [ "${1}" != "${2}" ] ; then

		echo 1>&2 "${this_script_fbn:?}: incorrect command: ${1}; expected: ${2}"
		false
	fi
}

function check_buildroot_output_selector() { # actual_value expected_value

	if [ "${1}" != "${2}" ] ; then

		echo 1>&2 "${this_script_fbn:?}: incorrect output selector: ${1}; expected: ${2}"
		false
	fi
}

##

function buildroot_cli_dispatcher() { # ...

	local command=
	local command_args=()
	local output_selector=

	while [ $# -gt 0 ] ; do
	case "${1}" in
	--output-main|--output-rol|--output-xctc)
		output_selector="${1#--output-}"

		shift 1
		;;

	-*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized/unsupported option: ${1}"

		return 2
		;;

	all-output-trees)
		output_selector="${output_selector:-${1:?}}"
		check_buildroot_output_selector "${output_selector:?}" "${1:?}" || return $?
		
		command="${command:-${1:?}}"
		check_buildroot_command "${command:?}" "${1:?}" || return $?

		shift 1 ; command_args+=( "$@" )

		shift $#
		;;

	eval)
		command="${command:-eval}"
		check_buildroot_command "${command:?}" "eval" || return $?

		shift 1 ; command_args+=( "$@" )

		shift $#
		;;

	host-tree|target-tree)
		case "${output_selector:-main}" in
		main|xctc)
			true
			;;
		*)
			echo 1>&2 "${FUNCNAME:?}: unsupported command for ${output_selector:?} build: ${1:?}"
			return 2
			;;
		esac

		command="${command:-${1:?}}"
		check_buildroot_command "${command:?}" "${1:?}" || return $?

		shift 1 ; command_args+=( "$@" )

		shift $#
		;;

	install|trip-test)
		output_selector="${output_selector:-${1:?}}"
		check_buildroot_output_selector "${output_selector:?}" "${1:?}" || return $?
		
		command="${command:-${1:?}}"
		check_buildroot_command "${command:?}" "${1:?}" || return $?

		shift 1 ; command_args+=( "$@" )

		shift $#
		;;

	make)
		command="${command:-make}"
		check_buildroot_command "${command:?}" "make" || return $?

		shift 1 ; command_args+=( "$@" )

		shift $#
		;;

	qemu-vm|rootfs-overlay)
		output_selector="${output_selector:-main}"
		check_buildroot_output_selector "${output_selector:?}" "main" || return $?
		
		command="${command:-${1:?}}"
		check_buildroot_command "${command:?}" "${1:?}" || return $?

		shift 1 ; command_args+=( "$@" )

		shift $#
		;;

	sdk|toolchain)
		output_selector="${output_selector:-xctc}"
		check_buildroot_output_selector "${output_selector:?}" "xctc" || return $?

		command="${command:-make}"
		check_buildroot_command "${command:?}" "make" || return $?

		command_args+=( "${1:?}" )

		shift 1
		;;

	main*defconfig|*main*defconfig)
		output_selector="${output_selector:-main}"
		check_buildroot_output_selector "${output_selector:?}" "main" || return $?

		command="${command:-make}"
		check_buildroot_command "${command:?}" "make" || return $?

		command_args+=( "${1:?}" )

		shift 1
		;;

	xctc*defconfig|*xctc*defconfig)
		output_selector="${output_selector:-xctc}"
		check_buildroot_output_selector "${output_selector:?}" "xctc" || return $?

		command="${command:-make}"
		check_buildroot_command "${command:?}" "make" || return $?

		command_args+=( "${1:?}" )

		shift 1
		;;

	*|'')
		command_args+=( "${1}" )

		shift 1
		;;
	esac;done

	#^-- TODO: add to command help's output: info about wrapper-specific commands

	command="${command:-make}"
	output_selector="${output_selector:-main}"

	case "${output_selector:?}" in
	all-output-trees|install|trip-test)
		true
		;;

	*)
		load_buildroot_config
		;;
	esac

	case "${output_selector:?}" in
	all-output-trees|install|trip-test)
		BR2_ENV_OUTPUT_DIR="NONE"
		BR2_ENV_CCACHE_DIR="NONE"
		;;

	main)
		BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:-${BR2_ENV_OUTPUT_DIR}}"
		BR2_ENV_CCACHE_DIR="${BR2_ENV_CCACHE_MAIN_DIR:-${BR2_ENV_CCACHE_DIR}}"
		;;

	rol)
		BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:-${BR2_ENV_OUTPUT_DIR}}"
		BR2_ENV_CCACHE_DIR="${BR2_ENV_CCACHE_MAIN_DIR:-${BR2_ENV_CCACHE_DIR}}"
		#^-- by design: the rol build uses the main buildroot config

		check_buildroot_command "${command:?}" "make" || return $?
		command="rootfs-overlay" #<-- by design: override

		case "x ${command_args[@]} x" in
		*" all "*|*" clean "*|x"  "x)
			case "x ${command_args[@]} x" in
			x" all clean "x|x" clean all "x)
				command_args=( --build --clean-first )
				;;
			x" all "x|x"  "x)
				command_args=( --build )
				;;
			x" clean "x)
				command_args=( --clean-only )
				;;
			*)
				echo 1>&2 "${FUNCNAME:?}: unsupported command(s) for ${output_selector:?} build: ${command_arg[@]}"
				return 2
				;;
			esac
			;;
		esac
		;;

	xctc)
		BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_XCTC_DIR:-${BR2_ENV_OUTPUT_DIR}}"
		BR2_ENV_CCACHE_DIR="${BR2_ENV_CCACHE_XCTC_DIR:-${BR2_ENV_CCACHE_DIR}}"

		! [[ ${command:?} == make ]] ||

		case "x ${command_args[@]} x" in
		*" all "*|*" toolchain "*|x"  "x)
			case "x ${command_args[@]} x" in
			*" sdk "*)
				true
				;;
			*)
				command_args+=( sdk )
				;;
			esac
			;;
		esac
		;;

	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized buildroot output selector: ${output_selector:?}"
		return 2
		;;
	esac

	: "${BR2_ENV_OUTPUT_DIR:?missing value for${output_selector:+ }${output_selector} build output directory}"

	##

	local command_env_vars01=()
	local command_env_vars02=()
	local command_env_vars03=()
	local command_env_vars04=()

	! [[ -n ${BR2_ENV_OUTPUT_DIR} ]] ||
	command_env_vars01+=( BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_DIR}" )

	! [[ -n ${BR2_ENV_CCACHE_DIR} ]] ||
	command_env_vars01+=( BR2_ENV_CCACHE_DIR="${BR2_ENV_CCACHE_DIR}" )

	! [[ -n ${BR2_ENV_DEBUG_WRAPPER:-${BR2_DEBUG_WRAPPER}} ]] ||
	command_env_vars02+=( BR2_DEBUG_WRAPPER="${BR2_ENV_DEBUG_WRAPPER:-${BR2_DEBUG_WRAPPER}}" )

	! [[ -n ${BR2_ENV_OUTPUT_DIR:-${BR2_OUTPUT_DIR}} ]] ||
	command_env_vars03+=( BR2_OUTPUT_DIR="${BR2_ENV_OUTPUT_DIR:-${BR2_OUTPUT_DIR}}" )

	! [[ -n ${BR2_ENV_CCACHE_DIR:-${BR2_CCACHE_DIR}} ]] ||
	command_env_vars03+=( BR2_CCACHE_DIR="${BR2_ENV_CCACHE_DIR:-${BR2_CCACHE_DIR}}" )

	! [[ -n ${BR2_ENV_EXTERNAL:-${BR2_EXTERNAL}} ]] ||
	command_env_vars04+=( BR2_EXTERNAL="${BR2_ENV_EXTERNAL:-${BR2_EXTERNAL}}" )

	! [[ -n ${BR2_ENV_DL_DIR:-${BR2_DL_DIR}} ]] ||
	command_env_vars04+=( BR2_DL_DIR="${BR2_ENV_DL_DIR:-${BR2_DL_DIR}}" )

	##

	local command_vars=()

	! [[ -n ${BR2_ENV_OUTPUT_DIR} ]] ||
	case "${command:?}" in
	make)
		command_vars+=( O="${BR2_ENV_OUTPUT_DIR:?}" )
		;;
	*)
		true # don't provide O via env; that name is too general
		;;
	esac

	##

	local invoke=()
	local command_handler=()

	case "${command:?}" in
	all-output-trees|install|trip-test)
		command_handler=( "buildroot_cli_handler_for_${command//-/_}" )

		command_env_vars+=()
		command_vars=()
		;;

	eval)
		command_handler=() ; invoke=( eval )

		command_env_vars+=( "${command_vars[@]}" )
		command_vars=()
		;;

	make)
		command_handler=( "buildroot_cli_handler_for_${command//-/_}" )
		;;	

	host-tree|qemu-vm|rootfs-overlay|target-tree)
		command_handler=( "buildroot_cli_handler_for_${command//-/_}" )

		command_env_vars+=( "${command_vars[@]}" )
		command_vars=()
		;;

	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized buildroot command: ${command:?}"
		return 2
		;;
	esac

	(
		local x1 i

		case "${command:?}" in
		all-output-trees|install|trip-test)
			true
			;;
		*)
			xx_pushd_buildroot
			;;
		esac

		i=0

		for x1 in "${command_env_vars01[@]}" ; do

			! [[ $((i ++)) -eq 0 ]] || xx :

			eval "xx export $(printf %q "${x1:?}")"
		done

		i=0

		for x1 in "${command_env_vars02[@]}" ; do

			! [[ $((i ++)) -eq 0 ]] || xx :

			eval "xx export $(printf %q "${x1:?}")"
		done

		i=0

		for x1 in "${command_env_vars03[@]}" ; do

			! [[ $((i ++)) -eq 0 ]] || xx :

			eval "xx export $(printf %q "${x1:?}")"
		done

		i=0

		for x1 in "${command_env_vars04[@]}" ; do

			! [[ $((i ++)) -eq 0 ]] || xx :

			eval "xx export $(printf %q "${x1:?}")"
		done

		( "${invoke[@]}" "${command_handler[@]}" "${command_vars[@]}" "${command_args[@]}" )

		if [[ "${output_selector:?}" == xctc && ${command:?} == make ]] ; then

			case "x ${command_args[@]} x" in
			*" clean "*|*" distclean "*|*" toolchain-"*"clean "*)

				# no special action to take: build housekeeping should not affect package archive
				;;

			*" sdk "*)

				register_buildroot_xctc_sdk_with_depot package_archive "${BR2_ENV_DL_DIR:?}" "${BR2_ENV_OUTPUT_DIR}" # new sdk

				withdraw_buildroot_xctc_sdk_from_depot download_cache "${BR2_ENV_DL_DIR:?}" "${BR2_ENV_OUTPUT_DIR}" # now stale

				trigger_download_of_buildroot_xctc_sdk_on_next_build_within "${BR2_ENV_OUTPUT_MAIN_DIR:?}"
				;;
			esac
		fi
	)
}

function xx_buildroot_cli_dispatcher() { # ...

	buildroot_cli_dispatcher "$@"
}

