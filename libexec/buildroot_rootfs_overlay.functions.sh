##/bin/bash
## Provides function buildroot_rootfs_overlay() and friends.
## 

[ -z "$buildroot_rootfs_overlay_functions_p" ] || return 0

buildroot_rootfs_overlay_functions_p=t

buildroot_rootfs_overlay_debug_p=

##

source assert.functions.sh

source as_list_with_separator.functions.sh

source buildroot_rootfs_overlay_tarball.functions.sh

source ensure_backup_of_original_file.functions.sh

##

source buildroot_config.functions.sh

##

function buildroot_rootfs_overlay() { # ...

	local action=
	local action_args=()

	local clean_first_p=

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

		shift 1
		;;
	--clean-first)
		action="${action:-build}"
		[ "${action:?}" = "build" ]

		clean_first_p=t

		shift 1
		;;
	--download-only)
		action="${action:-build}"
		[ "${action:?}" = "build" ]

		action_args+=( "${1}" )

		shift 1
		;;
	--run-hook-post-fakeroot)
		action="${action:-run_hook_post_fakeroot}"
		[ "${action:?}" = "run_hook_post_fakeroot" ]

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

        if [ -n "${clean_first_p}" ] ; then

		xx_buildroot_rootfs_overlay_clean
	fi

	"xx_buildroot_rootfs_overlay_${action:?}" "${action_args[@]}"
}

function buildroot_rootfs_overlay_build() { # [--download-only]

	local action_args=( "$@" )
	shift $#

        case "${BR2_ROOTFS_OVERLAY_CREATION_TOOL:?}" in
	debootstrap)
		true
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unsupported rootfs overlay creation tool: ${BR2_ROOTFS_OVERLAY_CREATION_TOOL:?}"
		return 1
		;;
	esac

	if [ -z "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH}" ] ; then

		echo 1>&2 "${this_script_fbn:?}: rootfs overlay creation using debootstrap is not configured; skipping"

		return 0
	fi

	if [ -e "${BR2_OUTPUT_ROL_DIR:?}.tar" ] ; then

		echo 1>&2 "${this_script_fbn:?}: nothing to do" #<-- minimize build time

		return 0
	fi

	local package_inclusion_list_comma_separated="$(
		eval "file_contents_as_list_with_separator "," ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_INCLUSION_FILE_LIST//,/ }"
	)"

	local package_exclusion_list_comma_separated="$(
		eval "file_contents_as_list_with_separator "," ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_EXCLUSION_FILE_LIST//,/ }"
	)"

	package_inclusion_list_comma_separated+="${package_inclusion_list_comma_separated:+","}$(
		eval "as_list_with_separator "," ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_INCLUSION_LIST//,/ }"
	)"

	local package_exclusion_list_comma_separated+="${package_exclusion_list_comma_separated:+","}$(
		eval "as_list_with_separator "," ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_PACKAGE_EXCLUSION_LIST//,/ }"
	)"

	: "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH:?missing value for BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH}"

	local arch="$(as_debian_arch "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH:?}")"
	#^-- goal: transparently map buildroot BR2_ARCH/KERNEL_ARCH/ARCH values to Debian values

	local variant="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_VARIANT}"
	case "${variant}" in standard) variant="" ;; esac

	xx sudo mkdir -p "${BR2_DL_ROL_DIR:?}"
	xx sudo mkdir -p "${BR2_OUTPUT_ROL_DIR:?}"

	xx sudo qemu-debootstrap \
		--verbose \
		--log-extra-deps \
		--keep-debootstrap-dir \
		--arch="${arch:?}" \
		${variant:+--variant="${variant:?}"} \
		${package_inclusion_list_comma_separated:+--include="${package_inclusion_list_comma_separated:?}"} \
		${package_exclusion_list_comma_separated:+--exclude="${package_exclusion_list_comma_separated:?}"} \
		--cache-dir="${BR2_DL_ROL_DIR:?}" \
		"${action_args[@]}" "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_SUITE:?}" "${BR2_OUTPUT_ROL_DIR:?}"

	#^-- NB: the rootfs overlay has files and directories that are not accessible to a non-root user

	#^-- NB: the rootfs overlay has files (programs) that are setuid root

	case ": ${action_args[@]} :" in
	*" --download-only "*) return $? ;;
	esac

	## 

	xx :

	(xx sudo find "${BR2_OUTPUT_ROL_DIR:?}"/var/cache -mindepth 1 -maxdepth 1 || :) |

	while read -r x1 ; do xx sudo rm -rf "${x1:?}" ; done

	#^-- empty contents of /var/cache

	##

	xx :

	xx sudo rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/hostname

	xx sudo rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/ld.so.cache

	xx sudo rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/resolv.conf

	#^-- ensure the rootfs overlay does not contain build host details

	##

	local d1 b1

	for d1 in "$(dirname "${BR2_OUTPUT_ROL_DIR:?}")" ; do
	for b1 in "$(basename "${BR2_OUTPUT_ROL_DIR:?}")" ; do
	(
		xx :

		xx cd "${d1:?}"

		create_buildroot_rootfs_overlay_tarball "${b1:?}.tar" "${b1:?}"
	)
	done;done

	assert_that [ -e "${BR2_OUTPUT_ROL_DIR:?}.tar" ] || return $?
}

function buildroot_rootfs_overlay_clean() { #

	local d1 x1

	for x1 in "${BR2_OUTPUT_ROL_DIR:?}.tar" ; do

		[ -e "${x1:?}" ] || continue

		xx sudo rm -rf "${x1:?}"
	done
 
	for d1 in "${BR2_OUTPUT_ROL_DIR:?}" ; do

		[ -e "${d1:?}" ] || continue

		xx sudo umount "${d1:?}"/sys  || :
		xx sudo umount "${d1:?}"/proc || :

		sudo find -H "${d1:?}" -mindepth 1 -maxdepth 1 | 
		while read -r x1 ; do xx sudo rm -rf "${x1:?}" ; done
	done
}

function buildroot_rootfs_overlay_run_hook_post_fakeroot() { # [target_rootfs_dpn]

	local target_rootfs_dpn="${1:-${TARGET_DIR:?}}" ; ! [ $# -ge 1 ] || shift 1

	local rc_did_apply_overlay_and_failed=2
	local rc_did_apply_overlay_and_succeeded=0
	local rc_did_not_apply_overlay_not_configured=1
	local rc

	if [ -z "${BR2_ROOTFS_OVERLAY_POST_FAKEROOT_TARBALL_LIST}" ] ; then

		rc=${rc_did_not_apply_overlay_not_configured:?}
	else
		(
			cd "${target_rootfs_dpn:?}" &&

			"${FUNCNAME:?}__extract_overlay" &&

			"${FUNCNAME:?}__setup_specified_users" &&

			"${FUNCNAME:?}__setup_specified_devices" &&

			:
		) &&

		rc=${rc_did_apply_overlay_and_succeeded:?} ||

		rc=${rc_did_apply_overlay_and_failed:?}
	fi

	if [ -n "${buildroot_rootfs_overlay_debug_p}" ] ; then

		xx : "${FUNCNAME:?}: rc = ${rc:?}"
	fi

        return ${rc:?}
}

function buildroot_rootfs_overlay_run_hook_post_fakeroot__extract_overlay() {

	local tarball_list_ws_delimited="${BR2_ROOTFS_OVERLAY_POST_FAKEROOT_TARBALL_LIST:?}"
	local tar_rc f1 x1

	for f1 in ${tarball_list_ws_delimited:?} ; do

		extract_from_buildroot_rootfs_overlay_tarball "${f1:?}" && tar_rc=$? || tar_rc=$?
		[ ${tar_rc:?} -eq 0 ] || break

		for x1 in debootstrap ; do

			[ -e "${x1:?}" ] || continue

			xx :

			xx rm -rf "${x1:?}"
		done
	done

	if [ -n "${buildroot_rootfs_overlay_debug_p}" ] ; then

		xx : "${FUNCNAME:?}: tar_rc = ${tar_rc:?}"
	fi

	[ ${tar_rc:?} -eq 0 ] || return 1
}

function buildroot_rootfs_overlay_run_hook_post_fakeroot__setup_specified_devices() {

	local build_output_host_dpn="${HOST_DIR:?}" # cf. buildroot post-fakeroot spec

	local build_output_fs_target_dpn="${TARGET_DIR:?}" # cf. buildroot post-fakeroot spec

	local build_output_fs_top_dpn="$(dirname "$(dirname "${TARGET_DIR:?}")")" # cf. buildroot impl

	local full_devices_table_fpn="${build_output_fs_top_dpn:?}/full_devices_table.txt" # cf. buildroot impl

	xx :

	xx "${build_output_host_dpn:?}/bin/makedevs" \
		-d "${full_devices_table_fpn:?}" "${build_output_fs_target_dpn:?}"
}

function buildroot_rootfs_overlay_run_hook_post_fakeroot__setup_specified_users() {

	local build_output_host_dpn="${HOST_DIR:?}" # cf. buildroot post-fakeroot spec

	local build_output_fs_target_dpn="${TARGET_DIR:?}" # cf. buildroot post-fakeroot spec

	local build_output_fs_top_dpn="$(dirname "$(dirname "${TARGET_DIR:?}")")" # cf. buildroot impl

	local full_users_table_fpn="${build_output_fs_top_dpn:?}/full_users_table.txt" # cf. buildroot impl

	ensure_backup_of_original_file etc/group
	ensure_backup_of_original_file etc/gshadow

	ensure_backup_of_original_file etc/passwd
	ensure_backup_of_original_file etc/shadow

	xx :

	xx "${BR2_ENV_CURRENT_BUILDROOT_DIR:?}/support/scripts/mkusers" \
		"${full_users_table_fpn:?}" "${build_output_fs_target_dpn:?}" | /bin/sh
}

##

function xx_buildroot_rootfs_overlay() { # ...

	buildroot_rootfs_overlay "$@"
}

function xx_buildroot_rootfs_overlay_clean() { # ...

	buildroot_rootfs_overlay_clean "$@"
}

function xx_buildroot_rootfs_overlay_build() { # ...

	buildroot_rootfs_overlay_build "$@"
}

function xx_buildroot_rootfs_overlay_run_hook_post_fakeroot() { #

	buildroot_rootfs_overlay_run_hook_post_fakeroot "$@"
}

