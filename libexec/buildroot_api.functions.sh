#!/bin/bash sourced
## Provides the buildroot API runtime.
## 

[ -z "$buildroot_api_functions_p" ] || return 0

buildroot_api_functions_p=t

buildroot_api_debug_p=

##

# if the directory of this script is not in PATH...

for _1_ in "$(dirname "$(realpath "${BASH_SOURCE:?}")")" ; do

	if [[ ::"${PATH}":: != *:"${_1_:?}":* ]] ; then

		PATH=${_1_:?}${PATH:+:}${PATH} # put it there
	fi
done

##

buildroot_api_modules=(

	all_output_trees
	config
	cwd
	host_tree
	install
	kernel_arch
	make
	qemu_vm
	rootfs_overlay
	rootfs_overlay_tarball
	target_tree
	trip_test
	xctc_sdk_depot
)

function buildroot_api() { # [ module ]

	local modules=()
	local module

	if [[ $# -eq 0 ]] ; then

		modules+=( "${buildroot_api_modules[@]}" )
	else
		modules+=( "${1}" )
	fi

	for module in "${modules[@]}" ; do

		echo "$(get_script_file_for_buildroot_api_module "${module}")"
	done
}

function get_script_file_for_buildroot_api_module() { # [ module ]

	local suffix=".functions.sh"

	local result=${BASH_SOURCE%${suffix}}${1:+_}${1}${suffix}

	if ! [[ -f ${result:?} ]] ; then

		local this_script_fbn="$(basename "$0")"
		local message_prefix="${this_script_name:-${this_script_fbn%.*sh}}: "

		echo 1>&2 "${message_prefix}unrecognized/unsupported buildroot API module: ${1:?}"
		return 2
	fi

	echo "${result:?}"
}

##

for _1_ in "${buildroot_api_modules[@]}" ; do

	[[ -n ${_1_} ]] || continue

	source "$(buildroot_api "${_1_:?}")"
done

##

source snippet_list_call_stack.functions.sh

source snippet_sudo_pass_through.functions.sh
source snippet_sudo_pass_through_real_gid.functions.sh
source snippet_sudo_pass_through_real_uid.functions.sh

source snippet_xx.functions.sh

##

