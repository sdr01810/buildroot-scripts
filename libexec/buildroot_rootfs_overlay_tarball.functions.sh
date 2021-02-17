##/bin/bash
## Provides function buildroot_rootfs_overlay_tarball() and friends.
## 

[ -z "$buildroot_rootfs_overlay_tarball_functions_p" ] || return 0

buildroot_rootfs_overlay_tarball_functions_p=t

buildroot_rootfs_overlay_tarball_debug_p=

##

function create_buildroot_rootfs_overlay_tarball() { # tarball_fpn rootfs_overlay_dpn

	local create_tarball="tar cf"

	local tarball_fpn="${1:?missing value for tarball_fpn}" ; shift 1
	local tarball_fpn_quoted="$(printf %q "${tarball_fpn:?}")"

	local rootfs_overlay_dpn="${1:?missing value for rootfs_overlay_dpn}" ; shift 1
	local rootfs_overlay_dpn_quoted="$(printf %q "${rootfs_overlay_dpn:?}")"

	local tar_opts_ws_delimited_quoted="${BR2_ROOTFS_OVERLAY_TAR_EXCLUSION_OPTS:-}"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--no-acls"
	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--no-selinux"
	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--no-xattrs"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--sparse"

	eval "xx ${create_tarball:?} ${tarball_fpn_quoted:?} ${tar_opts_ws_delimited_quoted} ${rootfs_overlay_dpn_quoted:?}"
}

function extract_from_buildroot_rootfs_overlay_tarball() { # tarball_fpn

	local extract_from_tarball="tar xf"

	local tarball_fpn="${1:?missing value for tarball_fpn}" ; shift 1
	local tarball_fpn_quoted="$(printf %q "${tarball_fpn:?}")"

	local tar_opts_ws_delimited_quoted="${BR2_ROOTFS_OVERLAY_TAR_EXCLUSION_OPTS:-}"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--no-acls"
	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--no-selinux"
	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--no-xattrs"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--same-owner"
	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--same-permissions"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--strip-components=1"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--keep-directory-symlink"

	tar_opts_ws_delimited_quoted+="${tar_opts_ws_delimited_quoted:+ }--delay-directory-restore"

	case "${f1:?}" in
	*.tar.bz2|*.tbz)
		extract_from_tarball="tar xjf"
		;;
	*.tar.gz|*.tgz)
		extract_from_tarball="tar xzf"
		;;
	*.tar.xz|*.txz)
		extract_from_tarball="tar xJf"
		;;
	esac
	#^-- TODO: use file(1) to determine tarball type

	xx :

	eval "xx ${extract_from_tarball:?} ${tarball_fpn_quoted:?} ${tar_opts_ws_delimited_quoted:?}"
}

