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

function buildroot_rootfs_overlay_build() { # [ --[not-]chrootable ] [ --download-only ] [ any_debootstrap_option ... ]

	local download_only_p=
	local option_chrootable=--chrootable

	local debootstrap_options=()
	local post_processing_options=()

	while [[ $# -gt 0 ]] ; do case "${1}" in
	--chrootable)
		option_chrootable=${1:?}
		shift 1
		;;
	--not-chrootable)
		option_chrootable=${1:?}
		shift 1
		;;
	--download-only)
		debootstrap_options+=( "${1}" )
		download_only_p=t
		shift 1
		;;
	--)
		shift 1
		break
		;;
	*|'')
		debootstrap_options+=( "${1}" )
		shift 1
		;;
	esac;done

	debootstrap_options+=( "$@" ) ; shift $#

	post_processing_options+=( ${option_chrootable:?} )

	if [[ ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_IS_ENABLED,,?} == n ]] ; then

		return 0
	fi

	if [[ ! -e ${BR2_OUTPUT_ROL_DIR:?}/debootstrap ]] ; then

		"${FUNCNAME:?}"__debootstrap "${debootstrap_options[@]}"

		post_processing_options+=( --did-just-create-rootfs-overlay )
	fi

	if [[ ! -n ${download_only_p} ]] ; then

		"${FUNCNAME:?}"__post_process "${post_processing_options[@]}"
	fi
}

function buildroot_rootfs_overlay_build__debootstrap() { # ...

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

	: "${arch:?invalid rootfs overlay debootstrap architecture spec: ${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_ARCH:?}}"

	local variant="${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_VARIANT}"
	case "${variant}" in standard) variant="" ;; esac

	local options=(

		--verbose

		--merged-usr

		--log-extra-deps

		--keep-debootstrap-dir

		${arch:+--arch="${arch:?}"}

		${variant:+--variant="${variant:?}"}

		${package_inclusion_list_comma_separated:+--include="${package_inclusion_list_comma_separated:?}"}
		${package_exclusion_list_comma_separated:+--exclude="${package_exclusion_list_comma_separated:?}"}

		--cache-dir="${BR2_DL_ROL_DIR:?}"
	)

	##

	local suite=${BR2_ROOTFS_OVERLAY_DEBOOTSTRAP_SUITE:?}

	local dist= archive_url_and_rc_script=()

	case "${suite:?}" in
	*:*|*:)
		dist=${suite%%:*} ; suite=${suite#*:}

		if [[ -z ${suite} ]] ; then

			echo 1>&2 "${FUNCNAME:?}: no suite specified; just distribution: ${dist:?}"
			return 2
		fi
		;;
	*)
		dist=debian
		;;
	esac

	case "${dist:?}" in
	debian)
		archive_url_and_rc_script=() # let debootstrap decide
		#^-- 
		#^-- stretch and above: archive URL is nominally <http://deb.debian.org/debian>
		#^-- 
		#^-- below stretch: archive URL is nominally <http://archive.debian.org/debian>
		;;

	ubuntu)
		archive_url_and_rc_script=( http://archive.ubuntu.com/${dist:?} )
		;;

	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized/unsupported distribution: ${dist:?}"
		return 2
		;;
	esac

	##

	(
		trap "$(printf %q "${FUNCNAME:?}"__finalize_with_trap_type) ERR" ERR
		trap "$(printf %q "${FUNCNAME:?}"__finalize_with_trap_type) EXIT" EXIT

		"${FUNCNAME:?}"__prepare

		xx :
		xx sudo_pass_through qemu-debootstrap "${options[@]}" "$@" \
			"${suite:?}" "${BR2_OUTPUT_ROL_DIR:?}" "${archive_url_and_rc_script[@]}"
	)
}

function buildroot_rootfs_overlay_build__debootstrap__prepare() { #

	buildroot_rootfs_overlay_util_ensure_no_mount_points_below "${BR2_OUTPUT_ROL_DIR:?}"
	#^-- sidestep bug in debootstrap(8): on failure, it can leave mount points behind

	xx :

	xx mkdir -p "${BR2_DL_ROL_DIR:?}"

	xx :

	xx mkdir -p "${BR2_OUTPUT_ROL_DIR:?}"
}

function buildroot_rootfs_overlay_build__debootstrap__finalize_with_trap_type() { # trap_type

	local trap_type=${1:?missing value for trap_type} ; shift 1

	if [[ -n ${buildroot_rootfs_overlay_debug_p} ]] ; then

		echo 1>&2
		echo 1>&2 "Finalizing debootstrap; trap type: ${trap_type} ..."
	fi

	buildroot_rootfs_overlay_util_ensure_no_mount_points_below "${BR2_OUTPUT_ROL_DIR:?}"
	#^-- sidestep bug in debootstrap(8): on failure, it can leave mount points behind

	if [[ ${trap_type} == ERR ]] ; then

		echo 1>&2
		echo 1>&2 "Interrupted/aborted; removing incomplete rootfs overlay ..."

		xx :

		xx sudo_pass_through rm -rf "${BR2_OUTPUT_ROL_DIR:?}"
	fi
}

function buildroot_rootfs_overlay_build__post_process() { # [ --[not-]chrootable ] [ --did-[not-]just-create-rootfs-overlay ]

	local chrootable_p=t did_just_create_rootfs_overlay_p=

	local invoking_uid invoking_gid root_uid=0 root_gid=0
	invoking_uid=$(sudo_pass_through_real_uid)
	invoking_gid=$(sudo_pass_through_real_gid)

	local d1 b1 x1

	while [[ $# -gt 0 ]] ; do case "${1}" in
	--chrootable)
		chrootable_p=t
		shift 1
		;;
	--not-chrootable)
		chrootable_p=
		shift 1
		;;
	--did-just-create-rootfs-overlay)
		did_just_create_rootfs_overlay_p=t
		shift 1
		;;
	--did-not-just-create-rootfs-overlay)
		did_just_create_rootfs_overlay_p=
		shift 1
		;;
	--)
		shift 1
		break
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unexpected argument(s): ${@}"
		return 2
		;;
	esac;done

	##

	for x1 in cached per_machine ; do

		"${FUNCNAME:?}"__remove_${x1:?}_data
	done

	if [[ ! -n ${chrootable_p} ]] ; then

		create_ownership_maps_for_buildroot_rootfs_overlay \
			"${BR2_OUTPUT_ROL_DIR:?}" "${invoking_uid:?}" "${invoking_gid:?}"
	else
		create_ownership_maps_for_buildroot_rootfs_overlay \
			"${BR2_OUTPUT_ROL_DIR:?}" "${root_uid:?}" "${root_gid:?}"
	fi

	for d1 in "$(dirname "${BR2_OUTPUT_ROL_DIR:?}")" ; do
	for b1 in "$(basename "${BR2_OUTPUT_ROL_DIR:?}")" ; do
	(
		[[ -e ${d1:?} ]] || continue

		xx :

		xx cd "${d1:?}"

		if [[ -n ${did_just_create_rootfs_overlay_p} || ! -e ${b1:?}.tar ]] ; then

			! [[ -e ${b1:?}.tar ]] || (xx : && xx rm -f "${b1:?}.tar")

			create_buildroot_rootfs_overlay_tarball "${b1:?}.tar" "${b1:?}"

			#^-- by design: we create the tarball before changing ownership of the rootfs overlay tree;
			#^-- this is because changing ownership will clear all setuid/setgid bits; see chown(2)

			[[ ${invoking_uid:?} -ne ${root_uid:?} || ${invoking_gid:?} -ne ${root_gid:?} ]] || continue

			xx : && xx sudo_pass_through chown "${invoking_uid:?}:${invoking_gid:?}" "${b1:?}.tar"
		fi
	)
	done;done

	if [[ ! -n ${chrootable_p} ]] ; then

		for d1 in "${BR2_DL_ROL_DIR:?}" "${BR2_OUTPUT_ROL_DIR:?}" ; do

			[[ ${invoking_uid:?} -ne ${root_uid:?} || ${invoking_gid:?} -ne ${root_gid:?} ]] || continue

			[[ -e ${d1} ]] || continue

			xx :

			xx sudo_pass_through find -H "${d1:?}" -depth -uid "${root_uid:?}" -exec chown -h "${invoking_uid:?}" {} \;

			xx sudo_pass_through find -H "${d1:?}" -depth -gid "${root_gid:?}" -exec chgrp -h "${invoking_gid:?}" {} \;
		done
	fi

	assert_that [ -s "${BR2_OUTPUT_ROL_DIR:?}.tar" ]
}

function buildroot_rootfs_overlay_build__post_process__remove_cached_data() { #

	(find "${BR2_OUTPUT_ROL_DIR:?}"/var/cache -mindepth 1 -maxdepth 1 2>&- || :) |

	while read -r x1 ; do

		[[ ${iter_count:=0} -gt 0 ]] || xx :

		xx sudo_pass_through rm -rf "${x1:?}"

		((++ iter_count))
	done

	#^-- empty contents of /var/cache
}

function buildroot_rootfs_overlay_build__post_process__remove_per_machine_data() { #

	xx :

	xx sudo_pass_through rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/hostname

	xx sudo_pass_through rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/resolv.conf

	#^-- remove data that is specific to the build host

	##

	xx :

	xx sudo_pass_through rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/ld.so.cache

	xx sudo_pass_through rm -rf "${BR2_OUTPUT_ROL_DIR:?}"/etc/machine-id

	#^-- remove data that is specific to each machine instantiation

	##

	local x1

	for x1 in "${BR2_OUTPUT_ROL_DIR:?}"/etc/.*.lock ; do

		[[ -e ${x1:?} ]] || continue

		xx :

		xx sudo_pass_through rm -rf "${x1:?}"

	done

	#^-- remove /etc lock files used by vipw(8) and friends

	##

	local x1

	for x1 in "${BR2_OUTPUT_ROL_DIR:?}"/{root,home/*}/.*history ; do

		[[ -e ${x1:?} ]] || continue

		xx :

		xx sudo_pass_through rm -rf "${x1:?}"
	done

	#^-- remove interactive history files that are specific to each user
}

function buildroot_rootfs_overlay_clean() { # [--tarball-only]

	local d1 x1

	for x1 in "${BR2_OUTPUT_ROL_DIR:?}.tar" ; do

		[ -e "${x1:?}" ] || continue

		xx :

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

		(find -H "${d1:?}" -mindepth 1 -maxdepth 1 || :) |

		while read -r x1 ; do

			[[ ${iter_count:=0} -gt 0 ]] || xx :

			xx sudo_pass_through rm -rf "${x1:?}"

			((++ iter_count))
		done
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

		echo 1>&2
		echo 1>&2 "${FUNCNAME:?}: rc = ${rc:?}"
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

	if [[ -n ${buildroot_rootfs_overlay_debug_p} ]] ; then

		echo 1>&2
		echo 1>&2 "${FUNCNAME:?}: tar_rc = ${tar_rc:?}"
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

	while read -r d1 ; do

		while mountpoint -q "${d1:?}" ; do

			xx :
			xx sudo_pass_through umount "${d1:?}"
		done
	done
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

