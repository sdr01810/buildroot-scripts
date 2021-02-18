##/bin/bash
## Provides function buildroot_rootfs_overlay() and friends.
##

[ -z "$buildroot_rootfs_overlay_functions_p" ] || return 0

buildroot_rootfs_overlay_functions_p=t

buildroot_rootfs_overlay_debug_p=

##

source assert.functions.sh

source as_list_with_separator.functions.sh

source debian_arch.functions.sh

source ensure_backup_of_original_file.functions.sh

source list_mount_points_below.functions.sh

##

source buildroot_config.functions.sh

source buildroot_rootfs_overlay_tarball.functions.sh

##

function buildroot_rootfs_overlay() { # ...

	local action=
	local action_args=()

	local clean_all_p=
	local clean_tarball_p=

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
	--clean-tarball-only)
		action="${action:-clean}"
		[ "${action:?}" = "clean" ]

		clean_tarball_p=t

		shift 1
		;;
	--clean-first)
		action="${action:-build}"
		[ "${action:?}" = "build" ]

		clean_all_p=t

		shift 1
		;;
	--clean-tarball-first)
		action="${action:-build}"
		[ "${action:?}" = "build" ]

		clean_tarball_p=t

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

        if [[ -n ${clean_all_p} ]] ; then

		xx_buildroot_rootfs_overlay_clean
	else
	if [[ -n ${clean_tarball_p} ]] ; then

		xx_buildroot_rootfs_overlay_clean --tarball-only
	fi;fi

	if [[ ${action:?} != clean ]] ; then

		"xx_buildroot_rootfs_overlay_${action:?}" "${action_args[@]}"
	fi
}

function buildroot_rootfs_overlay_build() { # [--download-only]

	local action_args=( "$@" )
	shift $#

	if [[ ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_IS_ENABLED:?} == n ]] ; then

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
	#^-- by design: transparently map buildroot BR2_ARCH/KERNEL_ARCH/ARCH values to Debian values

	local variant="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_VARIANT}"
	case "${variant}" in standard) variant="" ;; esac

	buildroot_rootfs_overlay_util_ensure_no_mount_points_below "${BR2_OUTPUT_ROL_DIR:?}"

	local rol_dl_and_output_dirs=( "${BR2_DL_ROL_DIR:?}" "${BR2_OUTPUT_ROL_DIR:?}" )

	local did_just_create_rol_output_dir_p=
	local did_just_create_rol_dl_dir_p=

	local d1

	if ! [[ -e ${BR2_OUTPUT_ROL_DIR:?}/debootstrap ]] ; then

		for d1 in "${rol_dl_and_output_dirs[@]}" ; do

			xx mkdir -p "${d1:?}"
		done

		(
			trap '
				buildroot_rootfs_overlay_util_ensure_no_mount_points_below "${BR2_OUTPUT_ROL_DIR:?}"
			' EXIT

			xx sudo_pass_through qemu-debootstrap \
				--verbose \
				--merged-usr \
				--log-extra-deps \
				--keep-debootstrap-dir \
				--arch="${arch:?}" \
				${variant:+--variant="${variant:?}"} \
				${package_inclusion_list_comma_separated:+--include="${package_inclusion_list_comma_separated:?}"} \
				${package_exclusion_list_comma_separated:+--exclude="${package_exclusion_list_comma_separated:?}"} \
				--cache-dir="${BR2_DL_ROL_DIR:?}" \
				"${action_args[@]}" "${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_SUITE:?}" "${BR2_OUTPUT_ROL_DIR:?}"

			#^-- NB: the rootfs overlay is a true chroot space w/ files that are root-only accessible and/or setuid
		)

		local uid gid
		uid=$(sudo_pass_through_real_uid)
		gid=$(sudo_pass_through_real_gid)

		if [[ ${uid:?} -ne 0 || ${gid:?} -ne 0 ]] ; then

			for d1 in "${rol_dl_and_output_dirs[@]}" ; do

				xx sudo_pass_through chown -R "${uid:?}:${gid:?}" "${d1:?}"
			done
		fi

		##

		did_just_create_rol_output_dir_p=t
		did_just_create_rol_dl_dir_p=t
	fi

	case ": ${action_args[@]} :" in
	*" --download-only "*)

		return $?
		;;
	esac

	if [[ -e ${BR2_OUTPUT_ROL_DIR:?}.tar && ! -n ${did_just_create_rol_output_dir_p} ]] ; then

		return 0
	fi

	##

	xx :

	(xx find "${BR2_OUTPUT_ROL_DIR:?}"/var/cache -mindepth 1 -maxdepth 1 2>&- || :) |

	while read -r x1 ; do xx rm -rf "${x1:?}" ; done

	#^-- empty contents of /var/cache

	##

	xx :

	xx rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/hostname

	xx rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/ld.so.cache

	xx rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/resolv.conf

	#^-- ensure the rootfs overlay does not contain build host details

	##

	xx :

	xx rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/machine-id

	#^-- ensure the rootfs overlay does not contain instance-specific data
	#^-- by design: each rootfs overlay needs to support multiple uses/instances

	##

	xx :

	xx rm -f "${BR2_OUTPUT_ROL_DIR:?}"/etc/.*.lock

	#^-- remove etc/ lock files (cf. vipw(8) and friends)

	##

	xx :

	xx rm -f "${BR2_OUTPUT_ROL_DIR:?}"/root/.*history

	#^-- remove interactive history files for user root

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

	assert_that [ -e "${BR2_OUTPUT_ROL_DIR:?}.tar" ]
	return $?
}

function buildroot_rootfs_overlay_clean() { # [--tarball-only]

	local d1 x1

	for x1 in "${BR2_OUTPUT_ROL_DIR:?}.tar" ; do

		[ -e "${x1:?}" ] || continue

		xx rm -rf "${x1:?}"
	done

	case ": ${@} :" in
	*" --tarball-only "*)

		return $?
		;;
	esac

	for d1 in "${BR2_OUTPUT_ROL_DIR:?}" ; do

		[ -e "${d1:?}" ] || continue

		buildroot_rootfs_overlay_util_ensure_no_mount_points_below "${d1:?}"

		find -H "${d1:?}" -mindepth 1 -maxdepth 1 |
		while read -r x1 ; do xx rm -rf "${x1:?}" ; done
	done
}

function buildroot_rootfs_overlay_run_hook_post_fakeroot() { # [target_rootfs_dpn]

	local target_rootfs_dpn=${1:-${TARGET_DIR:?}} ; ! [[ ${#} -ge 1 ]] || shift 1

	local rc_did_apply_overlay_and_failed=2
	local rc_did_apply_overlay_and_succeeded=0
	local rc_did_not_apply_overlay_not_configured=1
	local rc

	if [[ ${BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_IS_ENABLED:?} == n ]] ; then

		rc=${rc_did_not_apply_overlay_not_configured:?}
	else
	if ! [[ -n ${BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_TARBALL_LIST} ]] ; then

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
	fi;fi

	if [[ -n ${buildroot_rootfs_overlay_debug_p} ]] ; then

		xx : "${FUNCNAME:?}: rc = ${rc:?}"
	fi

        return ${rc:?}
}

function buildroot_rootfs_overlay_run_hook_post_fakeroot__extract_overlay() {

	local tarball_list_ws_delimited="${BR2_ROOTFS_OVERLAY_DURING_POST_FAKEROOT_TARBALL_LIST:?}"
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

	[ ${tar_rc:?} -eq 0 ]

	return $?
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

function buildroot_rootfs_overlay_util_ensure_no_mount_points_below() { # rootfs_overlay_dpn

	local rootfs_overlay_dpn=${1:?missing value for rootfs_overlay_dpn} ; shift 1

	list_mount_points_below "${rootfs_overlay_dpn:?}" |

	while read -r d1 ; do xx sudo_pass_through umount "${d1:?}" ; done
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

