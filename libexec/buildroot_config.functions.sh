##/bin/bash
## Provides utility functions for working with buildroot configurations.
## 

[ -z "$buildroot_config_functions_p" ] || return 0

buildroot_config_functions_p=t

buildroot_config_debug_p=

##

source buildroot_cwd.functions.sh
source buildroot_kernel_arch.functions.sh

source debian_arch.functions.sh

source omit_wsac.functions.sh

##

function cat_buildroot_config_quoted() {

	if [ -n "${BR2_ENV_OUTPUT_DIR}" ] ; then
	(
		cd_buildroot

		local BASE_DIR="${BR2_ENV_OUTPUT_DIR:?}" 

		local BR2_BASE_DIR="${BR2_ENV_OUTPUT_DIR:?}" 

		local BR2_CONFIG="${BR2_CONFIG:-${BR2_ENV_OUTPUT_DIR:?}/.config}"

		local CONFIG_DIR="${BR2_ENV_OUTPUT_DIR:?}" 

		local O="${BR2_ENV_OUTPUT_DIR:?}" 

		local TOPDIR="${PWD:?}"

		if ! [ -f "${BR2_CONFIG:?}" ] ; then

			echo 1>&2 "${FUNCNAME:?}: does not exist: ${BR2_CONFIG:?}; ignoring"
			true
		else
			eval local $(omit_wsac "${BR2_CONFIG:?}" | egrep '^BR2_(ARCH)=')

			local ARCH="${BR2_ARCH:?}" 

			local KERNEL_ARCH="$(as_buildroot_kernel_arch "${BR2_ARCH:?}")"

			omit_wsac "${BR2_CONFIG:?}" | sed \
				\
				-e "s#\$(ARCH)#${ARCH:?}#g" \
				-e "s#\$(BASE_DIR)#${BASE_DIR:?}#g" \
				-e "s#\$(BR2_BASE_DIR)#${BR2_BASE_DIR:?}#g" \
				-e "s#\$(BR2_CONFIG)#${BR2_CONFIG:?}#g" \
				-e "s#\$(CONFIG_DIR)#${CONFIG_DIR:?}#g" \
				-e "s#\$(KERNEL_ARCH)#${KERNEL_ARCH:?}#g" \
				-e "s#\$(O)#${O:?}#g" \
				-e "s#\$(TOPDIR)#${TOPDIR:?}#g" \
				\
				-e 's#\$#\\$#g' -e 's#(#{#g' -e 's#)#}#g' \
				;
		fi

	)
	else
		# not enough context to locate buildroot config
		true
	fi
}

function list_buildroot_config_variable_bindings() {

	set | egrep '^(BR_|BR2_|HOST)\w+=' |

	egrep -v '^HOST(NAME|TYPE)=' | #<-- defined by bash, not buildroot

	sort

	#^-- TODO: include variables defined by buildroot that do not match /^(BR_|BR2_|HOST)/
}

function list_buildroot_config_variable_names_defined() {

	list_buildroot_config_variable_bindings | sed -e 's/=.*//'
}

function list_buildroot_config_env_variable_names_defined() {

	list_buildroot_config_variable_names_defined | egrep '^BR2_ENV_'
}

function list_buildroot_config_non_env_variable_names_defined() {

	list_buildroot_config_variable_names_defined | egrep -v '^BR2_ENV_'
}

function load_buildroot_config() { # [--env {defaults|full}]

	local env_mode=defaults

        while [ $# -gt 0 ] ; do
	case "${1}" in
	--env)
		env_mode="${2:-${env_mode:?}}"
		! [ $# -ge 2 ] || shift 1
		shift 1
		;;
	--)
		shift 1
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unrecognized argument; ignoring."
		shift 1
		;;
	esac;done

	load_buildroot_config_defaults "${env_mode:?}"

	if ! eval $(cat_buildroot_config_quoted) ; then

		echo 1>&2 "${FUNCNAME:?}: unable to parse buildroot config file"
		return 2
	fi

	overlay_buildroot_br2_env_vars_onto_br2_vars

	if [ -n "${buildroot_config_debug_p}" ] ; then

		echo 1>&2 "${FUNCNAME:?}: buildroot config follows:"

		(print_buildroot_config | perl -pe 's#^#    #') 1>&2
	fi
}

function load_buildroot_config_defaults() { # [defaults|full]

	local env_mode=

	case "${1}" in
	defaults|full)
		env_mode="${1:?}"
		shift 1
		;;
	*|'')
		env_mode="defaults"
		echo 1>&2 "${FUNCNAME:?}: unrecognized env mode; using ${env_mode:?} instead"
		! [ $# -ge 1 ] || shift 1
		;;
	esac

	if [ "${env_mode:?}" = "full" ] ; then

		load_buildroot_config_defaults_file
	fi

	local components_with_config_defaults=( core rootfs_overlay )
	local component

	for component in "${components_with_config_defaults[@]}" ; do

		"${FUNCNAME:?}__${component:?}" "$@"
	done
}

function load_buildroot_config_defaults_file() {

	local f1="buildroot.env"

	! is_buildroot_dir ||
	f1="$(dirname "$(dirname "${f1:?}")")/$(basename "${f1:?}")"

	if ! [ -f "${f1:?}" ] ; then

		true # nothing to do
	else
	if ! source "${f1:?}" ; then

		echo 1>&2 "${FUNCNAME:?}: unable to parse file: ${f1:?}"
		return 2
	fi;fi
}

function load_buildroot_config_defaults__core() {

	export BR2_ENV_DEBUG_WRAPPER="${BR2_ENV_DEBUG_WRAPPER:-}"

	export BR2_ENV_DEFCONFIG="${BR2_ENV_DEFCONFIG:-}"

	export BR2_ENV_EXTERNAL="${BR2_ENV_EXTERNAL:-}"

	##

	local prefix=buildroot ; ! is_buildroot_dir || prefix="${PWD:?}"

	export BR2_ENV_DL_PTB_DIR="${BR2_ENV_DL_PTB_DIR:-$(realpath "${prefix:?}-dl-ptb")}"

	export BR2_ENV_OUTPUT_MAIN_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:-$(realpath "${prefix:?}-output-main")}"

	export BR2_ENV_OUTPUT_XCTC_DIR="${BR2_ENV_OUTPUT_XCTC_DIR:-$(realpath "${prefix:?}-output-xctc")}"

	##

	export BR2_ENV_DL_DIR="${BR2_ENV_DL_PTB_DIR:?}"

	export BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:?}"
}

function load_buildroot_config_defaults__rootfs_overlay() {

	: "${BR2_ENV_DL_PTB_DIR:?missing value for BR2_ENV_DL_PTB_DIR}"

	: "${BR2_ENV_OUTPUT_DIR:?missing value for BR2_ENV_OUTPUT_DIR}"

	##

	export BR2_ENV_DL_ROL_DIR="${BR2_ENV_DL_ROL_DIR:-${BR2_ENV_DL_PTB_DIR%dl*}dl-rol}"

	export BR2_ENV_OUTPUT_ROL_DIR="${BR2_ENV_OUTPUT_ROL_DIR:-${BR2_ENV_OUTPUT_MAIN_DIR%output*}output-rol}"

	##

	BR2_ROOTFS_OVERLAY_CREATION_TOOL="${BR2_ROOTFS_OVERLAY_CREATION_TOOL:-debootstrap}"

	! [ -n "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH}" ] ||
	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH="$(xx : && xx as_debian_arch "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH:?}")"

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_INCLUSION_FILE_LIST="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_INCLUSION_FILE_LIST:-}"

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_EXCLUSION_FILE_LIST="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_EXCLUSION_FILE_LIST:-}"

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_INCLUSION_LIST="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_INCLUSION_LIST:-}"

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_EXCLUSION_LIST="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_EXCLUSION_LIST:-}"

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_SUITE="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_SUITE:-oldstable}"
	#^-- for a full set of possible values see <https://wiki.debian.org/DebianReleases>
	#^-- 
	#^-- oldstable  : always maps to Debian's latest LTS (long term support) release
	#^-- stable     : always maps to Debian's latest stable release
	#^-- 
	#^-- stretch    : Debian LTS release (Debian 9) as of 2020-12

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_VARIANT="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_VARIANT:-}"
	#^-- "" == standard packages: all packages marked required and/or important

	##

	BR2_ROOTFS_OVERLAY_TAR_EXCLUSION_OPTS="${BR2_ROOTFS_OVERLAY_TAR_EXCLUSION_OPTS:-}"

	##

	if [ -n "${buildroot_rootfs_overlay_debug_p}" ] ; then

		echo 1>&2 "${FUNCNAME:?}: buildroot config follows:"

		(print_buildroot_config | perl -pe 's#^#    #') 1>&2
	fi
}

function overlay_buildroot_br2_env_vars_onto_br2_vars() {

	local br2_env_variable_names=( $(list_buildroot_config_env_variable_names_defined) )
	local br2_env_variable_name

	for br2_env_variable_name in "${br2_env_variable_names[@]}" ; do

		local br2_variable_name="${br2_env_variable_name/_ENV_/_}"	

		eval "${br2_variable_name:?}=$(printf %q "${!br2_env_variable_name}")"
	done

	BR2_DL_DIR="${BR2_ENV_DL_DIR:-${BR2_ENV_DL_PTB_DIR:?missing value for BR2_ENV_DL_PTB_DIR}}"

	#^-- This variable is 'special' because it is involved in bootstrapping the build.
	#^-- Consequently, its value in the buildroot .config file is often wrong.
	#^-- See `buildroot/Makefile` and the buildroot docs for further details.
	#^-- 
	#^-- To compensate, always overload it with its environment variable equivalent(s).
}

function print_buildroot_config() {

	local variable_names=( $(list_buildroot_config_variable_names_defined) )
	local variable_name

	for variable_name in "${variable_names[@]}" ; do

		echo "${variable_name:?}=${!variable_name}"
	done
}

function unset_buildroot_config() {

	local variable_names=( $(list_buildroot_config_variable_names_defined) )
	local variable_name

	for variable_name in "${variable_names[@]}" ; do

		unset "${variable_name:?}"
	done
}

