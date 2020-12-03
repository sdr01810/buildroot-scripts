##/bin/bash
## Provides utility functions for working with the buildroot current working directory.
## 

[ -z "$buildroot_cwd_functions_p" ] || return 0

buildroot_cwd_functions_p=t

buildroot_cwd_debug_p=

##

function get_buildroot_dir_from_stack() {

	local d1

	[ "${#DIRSTACK[@]}" -ge 1 ]

	if [ -n "${BR2_ENV_CURRENT_BUILDROOT_DIR}" ] ; then

		echo "${BR2_ENV_CURRENT_BUILDROOT_DIR:?}"

		return 0
	fi

        for d1 in "${DIRSTACK[@]}" ; do

		is_buildroot_dir "${d1:?}" || continue

		echo "${d1:?}"

		return 0
	done

        for d1 in "${DIRSTACK[@]}" ; do

		is_buildroot_dir "${d1:?}/buildroot" || continue

		echo "${d1:?}/buildroot"

		return 0
	done

	echo 1>&2 "${FUNCNAME:?}: cannot locate buildroot directory"
	return 1
}

function is_buildroot_dir() { # [directory_pn]

	local directory_pn="${1:-${PWD:?}}"
	local x1

	for x1 in "${directory_pn:?}"/Makefile ; do

		[ -s "${x1:?}" ] 2>/dev/null || return 1

		egrep -q '^# Makefile for buildroot' "${x1:?}" 2>/dev/null || return 1
	done
}

##

function cd_buildroot() {

	local buildroot_dpn="$(get_buildroot_dir_from_stack)" ; [ -n "${buildroot_dpn}" ]

	cd "${buildroot_dpn:?}" && export BR2_ENV_CURRENT_BUILDROOT_DIR="${PWD:?}"
}

function pushd_buildroot() {

	local buildroot_dpn="$(get_buildroot_dir_from_stack)" ; [ -n "${buildroot_dpn}" ]

	pushd "${buildroot_dpn:?}" && export BR2_ENV_CURRENT_BUILDROOT_DIR="${PWD:?}"
}

function xx_cd_buildroot() {

	local buildroot_dpn="$(get_buildroot_dir_from_stack)" ; [ -n "${buildroot_dpn}" ]

	xx cd "${buildroot_dpn:?}" && xx export BR2_ENV_CURRENT_BUILDROOT_DIR="${PWD:?}"
}

function xx_pushd_buildroot() {

	local buildroot_dpn="$(get_buildroot_dir_from_stack)" ; [ -n "${buildroot_dpn}" ]

	xx pushd "${buildroot_dpn:?}" && xx export BR2_ENV_CURRENT_BUILDROOT_DIR="${PWD:?}"
}

