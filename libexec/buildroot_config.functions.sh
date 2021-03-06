##/bin/bash
## Provides utility functions for working with buildroot configurations.
## 

[ -z "$buildroot_config_functions_p" ] || return 0

buildroot_config_functions_p=t

buildroot_config_debug_p=

##

source buildroot_cwd.functions.sh
source buildroot_kernel_arch.functions.sh

source omit_wsac.functions.sh

##

function cat_buildroot_config_quoted() { # [ --output-xctc | --output-main | --output-none ]

	local output_selector= output_dpn=${BR2_ENV_OUTPUT_DIR}

        while [ $# -gt 0 ] ; do
	case "${1}" in
	--output-xctc|--output-main)
		output_selector=${1#--output-}
		eval output_dpn=\${BR2_ENV_OUTPUT_${output_selector^^?}_DIR}

		shift 1
		;;

	--output-none)
		output_selector=${1#--output-}
		output_dpn=

		shift 1
		;;

	--)
		shift 1
		;;

	*|'')
		echo 1>&2 "${FUNCNAME:?}: unrecognized argument(s): ${@}"
		return 2
		;;
	esac;done

	if ! [[ -n ${output_dpn} ]] ; then

		# not enough context to locate buildroot config file
		true
	else
	(
		cd_buildroot

		# define interpolation feeders we already know:

		local BASE_DIR="${output_dpn:?}"

		local BR2_BASE_DIR="${output_dpn:?}"

		local BR2_CONFIG="${BR2_CONFIG:-${output_dpn:?}/.config}"

		local CONFIG_DIR="${output_dpn:?}"

		local O="${output_dpn:?}"

		local TOPDIR="${PWD:?}"

		if ! [[ -e ${BR2_CONFIG:?} ]] ; then

			# no buildroot config file at inferred location
			:
		else
			local buildroot_config_lines=$(omit_wsac "${BR2_CONFIG:?}")

			eval local $(echo "${buildroot_config_lines}" | egrep '^BR2_(ARCH)=')
			#^-- extract remaining interpolation feeders...

			local ARCH=${BR2_ARCH:?missing buildroot config value for BR2_ARCH}

			local KERNEL_ARCH=$(as_buildroot_kernel_arch "${BR2_ARCH:?}")

			# ...and interpolate
			echo "${buildroot_config_lines}" | sed \
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
	fi
}

function list_buildroot_config_variable_bindings() { # [ --env-omit | --env-only | --env-too }

	local env_selection_mode=too

	while [[ ${#} -gt 0 ]] ; do
	case "${1}" in
	--env-omit|--env-only|--env-too)
		env_selection_mode=${1#--env-}

		shift 1
		;;
	--)
		shift 1
		;;
	-*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized option: ${1}"
		return 2
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unrecognized argument(s): ${@}"
		return 2
		;;
	esac;done

	(set -o posix && set) |

	(egrep '^(BR_|BR2_|CCACHE_|HOST)\w+=' || :) |

	#^-- TODO: include additional variables defined/honored by buildroot

	(egrep -v '^HOST(NAME|TYPE)=' || :) | #<-- defined by bash, not buildroot

	case "${env_selection_mode:?}" in
	omit)
		(egrep -v '^BR2_ENV' || :)
		;;
	only)
		(egrep '^BR2_ENV' || :)
		;;
	too)
		cat
		;;
	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized env_selection_mode: ${1}"
		return 2
		;;
	esac |

	sort
}

function list_buildroot_config_variable_names_defined() { # [ --env-omit | --env-only | --env-too }

	list_buildroot_config_variable_bindings "$@" | sed -e 's/=.*//'
}

function load_buildroot_config() { # [ --defaults { file-too | file-omit | file-only } [ --output-xctc | --output-main | --output-none ]

	local defaults_mode=file-too output_selector=

        while [ $# -gt 0 ] ; do
	case "${1}" in
	--defaults)
		defaults_mode=${2:?missing value for defaults_mode}

		shift 2
		;;

	--output-xctc|--output-main|--output-none)
		output_selector=${1#--output-}

		shift 1
		;;

	--)
		shift 1
		;;

	*|'')
		echo 1>&2 "${FUNCNAME:?}: unrecognized argument(s): ${@}"
		return 2
		;;
	esac;done

	load_buildroot_config__defaults --"${defaults_mode:?}"

	if ! eval $(cat_buildroot_config_quoted ${output_selector:+--output-${output_selector}}) ; then

		echo 1>&2 "${FUNCNAME:?}: unable to parse buildroot config file"
		return 2
	fi

	load_buildroot_config__overlay_br2_env_onto_br2

	if [[ -n ${buildroot_config_debug_p} ]] ; then

		echo 1>&2
		echo 1>&2 "${FUNCNAME:?}: buildroot config follows:"
		echo 1>&2

		(print_buildroot_config | perl -pe 's#^#    #') 1>&2
	fi
}

function load_buildroot_config__defaults() { # [ --file-too | --file-only | --file-omit ]

	local defaults_mode=file-too

        while [ $# -gt 0 ] ; do
	case "${1}" in
	--file-omit|--file-only|--file-too)
		defaults_mode=${1#--}

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

	local components_with_config_defaults=()
	local component

	if [[ ${defaults_mode:?} != file-omit ]] ; then

		components_with_config_defaults+=( customization_file )
	fi
	#^-- by design: load defaults from customization file *first*

	if [[ ${defaults_mode:?} != file-only ]] ; then

		components_with_config_defaults+=( core rootfs_overlay )
	fi
	#^-- by design: load defaults from built-in components *last*

	for component in "${components_with_config_defaults[@]}" ; do

		"${FUNCNAME:?}__${component:?}" "$@"
	done
}

function load_buildroot_config__defaults__customization_file() {

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

function load_buildroot_config__defaults__core() {

	export BR2_ENV_DEBUG_WRAPPER="${BR2_ENV_DEBUG_WRAPPER:-}"

	export BR2_ENV_EXTERNAL="${BR2_ENV_EXTERNAL:-}"

	##

	local prefix=buildroot ; ! is_buildroot_dir || prefix="${PWD:?}"

	export BR2_ENV_DL_PTB_DIR="${BR2_ENV_DL_PTB_DIR:-$(realpath "${prefix:?}-dl-ptb")}"

	export BR2_ENV_OUTPUT_MAIN_DIR="${BR2_ENV_OUTPUT_MAIN_DIR:-$(realpath "${prefix:?}-output-main")}"
	export BR2_ENV_CCACHE_MAIN_DIR="${BR2_ENV_CCACHE_MAIN_DIR:-$(realpath "${prefix:?}-ccache-main")}"

	export BR2_ENV_OUTPUT_XCTC_DIR="${BR2_ENV_OUTPUT_XCTC_DIR:-$(realpath "${prefix:?}-output-xctc")}"
	export BR2_ENV_CCACHE_XCTC_DIR="${BR2_ENV_CCACHE_XCTC_DIR:-$(realpath "${prefix:?}-ccache-xctc")}"

	##

	export BR2_ENV_DL_DIR="${BR2_ENV_DL_PTB_DIR:?}"

	export BR2_ENV_OUTPUT_DIR="${BR2_ENV_OUTPUT_DIR:-}"
	export BR2_ENV_CCACHE_DIR="${BR2_ENV_CCACHE_DIR:-}"
}

function load_buildroot_config__defaults__rootfs_overlay() {

	: "${BR2_ENV_DL_PTB_DIR:?missing value for BR2_ENV_DL_PTB_DIR}"

	##

	export BR2_ENV_DL_ROL_DIR="${BR2_ENV_DL_ROL_DIR:-${BR2_ENV_DL_PTB_DIR%dl*}dl-rol}"

	export BR2_ENV_OUTPUT_ROL_DIR="${BR2_ENV_OUTPUT_ROL_DIR:-${BR2_ENV_OUTPUT_MAIN_DIR%output*}output-rol}"

	##

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_IS_ENABLED="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_IS_ENABLED:-n}"

	BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH:-}"

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

	BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_IS_ENABLED="${BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_IS_ENABLED:-n}"

	BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_TARBALL_LIST="${BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_TARBALL_LIST:-}"

	##

	BR2_ROOTFS_OVERLAY_TAR_EXCLUSION_OPTS="${BR2_ROOTFS_OVERLAY_TAR_EXCLUSION_OPTS:-}"

	##

	if [[ -n ${buildroot_config_debug_p} ]] ; then

		echo 1>&2
		echo 1>&2 "${FUNCNAME:?}: buildroot config follows:"
		echo 1>&2

		(print_buildroot_config | perl -pe 's#^#    #') 1>&2
	fi
}

function load_buildroot_config__overlay_br2_env_onto_br2() {

	local br2_env_variable_names=( $(list_buildroot_config_variable_names_defined --env-only) )
	local br2_env_variable_name

	for br2_env_variable_name in "${br2_env_variable_names[@]}" ; do

		[[ -n ${!br2_env_variable_name} ]] || continue

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

