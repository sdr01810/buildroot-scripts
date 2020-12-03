##/bin/bash
## Provides function buildroot_dispatcher() and friends.
## 

[ -z "$buildroot_dispatcher_functions_p" ] || return 0

buildroot_dispatcher_functions_p=t

buildroot_dispatcher_debug_p=

##

source assert.functions.sh

source buildroot_config.functions.sh
source buildroot_cwd.functions.sh

##

function check_buildroot_action() { # actual_value expected_value

	if [ "${1}" != "${2}" ] ; then

		echo 1>&2 "${this_script_fbn:?}: incorrect action: ${1}; expected: ${2}"
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

function buildroot_dispatcher() { # ... 

	local action=
	local action_args=()
	local output_selector=
	local x1= x2=

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
		
		action="${action:-${1:?}}"
		check_buildroot_action "${action:?}" "${1:?}" || return $?

		shift 1 ; action_args+=( "$@" )

		shift $#
		;;

	eval)
		action="${action:-eval}"
		check_buildroot_action "${action:?}" "eval" || return $?

		shift 1 ; action_args+=( "$@" )

		shift $#
		;;

	host-tree|target-tree)
		case "${output_selector:-main}" in
		main|xctc)
			true
			;;
		*)
			echo 1>&2 "${FUNCNAME:?}: unsupported action for ${output_selector:?} build: ${1:?}"
			return 2
			;;
		esac

		action="${action:-${1:?}}"
		check_buildroot_action "${action:?}" "${1:?}" || return $?

		shift 1 ; action_args+=( "$@" )

		shift $#
		;;

	install|trip-test)
		output_selector="${output_selector:-${1:?}}"
		check_buildroot_output_selector "${output_selector:?}" "${1:?}" || return $?
		
		action="${action:-${1:?}}"
		check_buildroot_action "${action:?}" "${1:?}" || return $?

		shift 1 ; action_args+=( "$@" )

		shift $#
		;;

	make)
		action="${action:-make}"
		check_buildroot_action "${action:?}" "make" || return $?

		shift 1 ; action_args+=( "$@" )

		shift $#
		;;

	qemu-vm|rootfs-overlay)
		output_selector="${output_selector:-main}"
		check_buildroot_output_selector "${output_selector:?}" "main" || return $?
		
		action="${action:-${1:?}}"
		check_buildroot_action "${action:?}" "${1:?}" || return $?

		shift 1 ; action_args+=( "$@" )

		shift $#
		;;

	sdk|toolchain)
		output_selector="${output_selector:-xctc}"
		check_buildroot_output_selector "${output_selector:?}" "xctc" || return $?

		action="${action:-make}"
		check_buildroot_action "${action:?}" "make" || return $?

		action_args+=( "${1:?}" )

		shift 1
		;;

	main*defconfig|*main*defconfig)
		output_selector="${output_selector:-main}"
		check_buildroot_output_selector "${output_selector:?}" "main" || return $?

		action="${action:-make}"
		check_buildroot_action "${action:?}" "make" || return $?

		action_args+=( "${1:?}" )

		shift 1
		;;

	xctc*defconfig|*xctc*defconfig)
		output_selector="${output_selector:-xctc}"
		check_buildroot_output_selector "${output_selector:?}" "xctc" || return $?

		action="${action:-make}"
		check_buildroot_action "${action:?}" "make" || return $?

		action_args+=( "${1:?}" )

		shift 1
		;;

	*|'')
		action_args+=( "${1}" )

		shift 1
		;;
	esac;done

	#^-- TODO: add to command help's output: info about wrapper-specific commands

	action="${action:-make}"
	output_selector="${output_selector:-main}"

	case "${output_selector:?}" in
	all-output-trees|install|trip-test)
		true
		;;

	*)
		load_buildroot_config --env full

		: "${BR2_ENV_OUTPUT_MAIN_DIR:?missing value for BR2_ENV_OUTPUT_MAIN_DIR}"
		: "${BR2_ENV_OUTPUT_XCTC_DIR:?missing value for BR2_ENV_OUTPUT_XCTC_DIR}"
		;;
	esac

	case "${output_selector:?}" in
	all-output-trees|install|trip-test)
		BR2_ENV_OUTPUT_DIR="NONE"
		;;

	main)
		BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:?}"
		;;

	rol)
		BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:?}"
		#^-- by design: the rol build uses the main buildroot config

		check_buildroot_action "${action:?}" "make" || return $?
		action="rootfs-overlay" #<-- by design: override

		case "x ${action_args[@]} x" in
		*" all "*|*" clean "*|x"  "x)
			case "x ${action_args[@]} x" in
			x" all clean "x|x" clean all "x)
				action_args=( --build --clean-first )
				;;
			x" all "x|x"  "x)
				action_args=( --build )
				;;
			x" clean "x)
				action_args=( --clean-only )
				;;
			*)
				echo 1>&2 "${FUNCNAME:?}: unsupported action(s) for ${output_selector:?} build: ${action_arg[@]}"
				return 2
				;;
			esac
			;;
		esac
		;;

	xctc)
		BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_XCTC_DIR:?}"

		case "x ${action_args[@]} x" in
		*" all "*|*" toolchain "*|x"  "x)
			case "x ${action_args[@]} x" in
			*" sdk "*)
				true
				;;
			*)
				action_args+=( sdk )
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

	local action_env_vars=()

	! [ -n "${BR2_DL_DIR:-${BR2_ENV_DL_DIR}}" ] ||
	action_env_vars+=( BR2_DL_DIR="${BR2_DL_DIR:-${BR2_ENV_DL_DIR:?}}" )

	! [ -n "${BR2_DEBUG_WRAPPER:-${BR2_ENV_DEBUG_WRAPPER}}" ] ||
	action_env_vars+=( BR2_DEBUG_WRAPPER="${BR2_DEBUG_WRAPPER:-${BR2_ENV_DEBUG_WRAPPER:?}}" )

	! [ -n "${BR2_EXTERNAL:-${BR2_ENV_EXTERNAL}}" ] ||
	action_env_vars+=( BR2_EXTERNAL="${BR2_EXTERNAL:-${BR2_ENV_EXTERNAL:?}}" )

	local action_vars=()

	! [ -n "${BR2_DEFCONFIG:-${BR2_ENV_DEFCONFIG}}" ] ||
	action_vars+=( BR2_DEFCONFIG="${BR2_DEFCONFIG:-${BR2_ENV_DEFCONFIG:?}}" )

	! [ -n "${BR2_ENV_OUTPUT_DIR}" ] || 
	case "${action:?}" in
	make)
		action_vars+=( O="${BR2_ENV_OUTPUT_DIR:?}" )
		;;
	*)
		true # don't provide O via env; that name is too general
		;;
	esac

	local invoke=( xx_env )
	local action_cmd=() 

	case "${action:?}" in
	all-output-trees|install|trip-test)
		action_cmd=( "$(which "buildroot.${action:?}.sh")" )
		[ -n "${action_cmd[0]}" ]

		action_env_vars+=()
		action_vars=()
		;;

	eval)
		action_cmd=() ; invoke=( xx_eval )

		action_env_vars+=( "${action_vars[@]}" )
		action_vars=()
		;;

	make)
		action_cmd=( "$(which "${action:?}")" )
		[ -n "${action_cmd[0]}" ]
		;;	

	host-tree|qemu-vm|rootfs-overlay|target-tree)
		action_cmd=( "$(which "buildroot.${action:?}.sh")" )
		[ -n "${action_cmd[0]}" ]

		action_env_vars+=( "${action_vars[@]}" )
		action_vars=()
		;;

	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized buildroot action: ${action:?}"
		return 2
		;;
	esac

	(
		case "${action:?}" in
		all-output-trees|install|trip-test)
			true
			;;
		*)
			xx_pushd_buildroot
			;;
		esac

		"${invoke[@]}" "${action_env_vars[@]}" "${action_cmd[@]}" "${action_vars[@]}" "${action_args[@]}"

		case "${output_selector:?}" in
		xctc)
			for x1 in "${BR2_ENV_OUTPUT_DIR:?}"/images ; do
			for x2 in "${BR2_ENV_DL_DIR:?}/buildroot-xctc" ; do
				! [ -e "${x1:?}" ] || xx rsync -a -u -i "${x1:?}"/ "${x2:?}"/
			done;done
			;;
		esac
	)
}

function xx_buildroot_dispatcher() { # ... 

	buildroot_dispatcher "$@"
}

