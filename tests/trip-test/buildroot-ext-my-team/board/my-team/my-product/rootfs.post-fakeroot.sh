#!/bin/bash
## Perform final adjustments to the rootfs target tree for a particular filesystem image.
##
## Arguments:
##
##     [target-output-directory]
##
## Inherited from parent (buildroot post-fakeroot) environment:
##
##     TARGET_DIR
##
## Typical uses:
##
##     rootfs.post-fakeroot.sh buildroot-output-main/build/buildroot-fs/cpio
##

source "$(dirname "$0")"/buildroot-hook.prolog.sh

##

init_process_fpn="sbin/init"

login_shell_registry_fpn="etc/shells"

product_installation_type_fbn=".product.installation.type"

##

_post_build_in=".post-build.in"

##
## from snippets library:
##

function ensure_backup_of_original_file() { # file_pn

	local file_pn="${1:?missing value for file_pn}" ; shift 1
	local x1 x2

	for x1 in "${file_pn:?}" ; do
	for x2 in "${file_pn:?}.orig" ; do

		[ -e "${x1:?}" -a ! -e "${x2:?}" ] || continue

		xx :

		xx cp "${x1:?}" "${x2:?}"
	done;done
}

function get_os_release_info_based_on() { # os_release_info_fpn ...

	: "${1:?missing value for os_release_info_fpn}"

	(
		for f1 in "$@" ; do

			eval "$(omit_wsac "${f1:?}")"
		done

		ID_LIKE_orig="${ID_LIKE}"
		ID_orig="${ID}"
		NAME_orig="${NAME}"
		PRETTY_NAME_orig="${PRETTY_NAME}"
		VERSION_CODENAME_orig="${VERSION_CODENAME}"
		VERSION_ID_orig="${VERSION_ID}"
		VERSION_orig="${VERSION}"

		case "//${ID}/${ID_LIKE}//" in
		//buildroot/*/|/////)

			VERSION_ID="$(date --rfc-3339=date)"
			VERSION_CODENAME="${ID_orig:?}"
			;;

		//debian/*/|/*/debian/)

			true
			;;

		*)
			echo 1>&2 "${this_script_fbn:?}: unsupported OS release ID: ${ID:?}"
			return 2
			;;
		esac

		: "${VERSION_ID:?missing value for VERSION_ID}"
		: "${VERSION_CODENAME:?missing value for VERSION_CODENAME}"

		echo "ID_LIKE_orig=$(printf %q "${ID_LIKE_orig}")"
		echo "ID_orig=$(printf %q "${ID_orig}")"
		echo "NAME_orig=$(printf %q "${NAME_orig}")"
		echo "PRETTY_NAME_orig=$(printf %q "${PRETTY_NAME_orig}")"
		echo "VERSION_CODENAME_orig=$(printf %q "${VERSION_CODENAME_orig}")"
		echo "VERSION_ID_orig=$(printf %q "${VERSION_ID_orig}")"
		echo "VERSION_orig=$(printf %q "${VERSION_orig}")"

		echo "VERSION_CODENAME=$(printf %q "${VERSION_CODENAME}")"
		echo "VERSION_ID=$(printf %q "${VERSION_ID}")"
	)
}

function omit_wsac() { # ...

	cat "$@" | egrep -v '^\s*(#|$)'
}

function xx() { # ...

	echo 1>&2 "${PS4:-+}" "$@"
	"$@"
}

##
## core logic:
##

function apply_rootfs_overlay_during_post_fakeroot_if_configured() { # [target_rootfs_dpn]

	local build_output_fs_target_dpn="${1:-${TARGET_DIR:?}}"

	local rc_did_apply_overlay_and_failed=2
	local rc_did_apply_overlay_and_succeeded=0
	local rc_did_not_apply_overlay_not_configured=1

	case "${build_output_fs_target_dpn:?}" in
	*/cpio/target)
		# do not apply rootfs overlay(s) to the initrd image;
		# doing so would make it too big for standard Linux kernel support

		mark_product_installation_type "initrd without rootfs overlay"

		return ${rc_did_not_apply_overlay_not_configured:?}
		;;
	esac

	local c1="buildroot.sh"

	if ! command -v "$c1" >/dev/null ; then

		mark_product_installation_type "boot disk without rootfs overlay"

		return ${rc_did_not_apply_overlay_not_configured:?}
	fi

	mark_product_installation_type "boot disk with rootfs overlay"

	xx :

	xx "${c1:?}" rootfs-overlay --run-hook-post-fakeroot "$@"

	return $?
}

function ensure_linuxrc_delegates_to_init_process() {

	xx :

	xx ln -snf "${init_process_fpn:?}" linuxrc
}

function ensure_linuxrc_does_not_exist_since_it_is_obsolete() {

	if [ -e linuxrc ] ; then

		xx :

		xx rm -f linuxrc
	fi
}

function ensure_registry_entry_for_login_shell_if_exists() { # login_shell_fpn

	local login_shell_fpn="${1:?missing value for login_shell_fpn}" ; shift 1

	xx :

	ensure_backup_of_original_file "${login_shell_registry_fpn:?}"

        if [ ! -e "${login_shell_fpn#/}" ] ; then

		return 0
	fi

	if xx fgrep -q -x "${login_shell_fpn:?}" "${login_shell_registry_fpn:?}" ; then

		xx : entry already exists
	else
	(
		xx umask 022

		xx echo "${login_shell_fpn:?}" >> "${login_shell_registry_fpn:?}"
	)
	fi
}

function ensure_systemd_default_target_is() { # desired_target_name

	local desired_target_name="${1:-?missing value for desired_target_name}"

	local desired_target_fpn="/lib/systemd/system/${desired_target_name%.target}.target"

	if ! rootfs_init_process_is systemd ; then

		return 0 # nothing to do
	fi

	if ! [ -e "${desired_target_fpn#/}" ] ; then

		echo 1>&2 "${this_script_fbn:?}: does not exist: ${desired_target_fpn#/}"
		return 2
	fi

	xx :

	xx [ -d "etc/systemd/system" ]

	xx ln -snf "${desired_target_fpn:?}" "etc/systemd/system/default.target"
}

function ensure_rootfs_has_init_process() {

	if [ ! -e "${init_process_fpn:?}" ] ; then

		echo 1>&2 "Cannot happen: rootfs does not provide /${init_process_fpn#/}"
		return 2
	fi
}

function mark_product_installation_type() { # ...

	local f1

	for f1 in "${product_installation_type_fbn:?}" ; do
	(
		xx :

		xx umask 222

		xx echo "${@:?missing value for product installation type}" | 

		xx tee "${f1:?}"
	)
	done
}

function remove_post_build_template_files() {

	xx :

	xx find etc usr/lib -mindepth 1 -maxdepth 2 -name "*${_post_build_in:?}" -print -delete
}

function rootfs_init_process_is() { # expected_init_process_fbn

	local expected_init_process_fbn="${1:?missing value for expected_init_process_fbn}"

	local init_process_fpn="/sbin/init"

	[ -L "${init_process_fpn#/}" ]

	case "$(readlink "${init_process_fpn#/}")" in
	*/"${expected_init_process_fbn##*/}")
		true
		;;
	*|'')
		false
		;;
	esac
}

function setup_bare_bones_init_process() {

	local x1 x2

	for x1 in bin/sh ; do

		xx :

		xx [ -x "${x1:?}" ]

		xx [ -x "${init_process_fpn:?}" ]

		case "/${init_process_fpn#/}" in
		/*/*/*)
			echo 1>&2 "Cannot happen: init process is not a child of a top-level directory"
			;;
		/*/*)
			xx ln -snf ../"${x1:?}" "${init_process_fpn:?}"
			;;
		/*)
			echo 1>&2 "Cannot happen: init process is not a child of a top-level directory"
			;;
		esac
	done

	for x1 in etc/init.d ; do
	for x2 in "${x1:?}"/rcS ; do

		xx :

		xx mkdir -p "${x1:?}"

		xx echo : | xx cp /dev/stdin "${x2:?}"

		xx chmod +x "${x2:?}"
	done;done
}

function setup_hostname() {

	local x1 x1_in

	for x1 in etc/hostname ; do
	for x1_in in "${x1:?}${_post_build_in:?}" ; do

		if [ -e "${x1_in:?}" ] ; then
		(
			xx :

			xx umask 022

			xx cat "${x1_in:?}" |

			xx sed -e '/./!d' | # TODO: add a uniquifier to host name

			xx tee "${x1:?}"
		)
		fi

		[ -e "${x1:?}" ]
	done;done
}

function setup_login_shell_registry() {

	ensure_registry_entry_for_login_shell_if_exists /bin/ash
	ensure_registry_entry_for_login_shell_if_exists /bin/hush
	ensure_registry_entry_for_login_shell_if_exists /bin/sh

	#^-- these might be provided by BusyBox even without a rootfs overlay
}

function setup_os_release_info() {

	local x1 x1_in

	for x1 in usr/lib/os-release ; do
	for x1_in in "${x1:?}${_post_build_in:?}" ; do

		ensure_backup_of_original_file "${x1:?}"

		if [ -e "${x1_in:?}" ] ; then
		(
			eval "$(get_os_release_info_based_on "${x1:?}.orig")"

			xx :

			xx umask 022

			xx omit_wsac "${x1_in:?}" |

			xx sed \
				-e 's#\${ID_LIKE_orig}#'"${ID_LIKE_orig}"'#g' \
				-e 's#\${ID_orig}#'"${ID_orig}"'#g' \
				-e 's#\${NAME_orig}#'"${NAME_orig}"'#g' \
				-e 's#\${PRETTY_NAME_orig}#'"${PRETTY_NAME_orig}"'#g' \
				-e 's#\${VERSION_CODENAME_orig}#'"${VERSION_CODENAME_orig}"'#g' \
				-e 's#\${VERSION_ID_orig}#'"${VERSION_ID_orig}"'#g' \
				-e 's#\${VERSION_orig}#'"${VERSION_orig}"'#g' \
				\
				-e 's#\${VERSION_CODENAME}#'"${VERSION_CODENAME}"'#g' \
				-e 's#\${VERSION_ID}#'"${VERSION_ID}"'#g' \
				\
				-e 's#_template=#=#' |

			xx tee "${x1:?}"
		)
		fi

		xx :

		xx [ -e "${x1:?}" ]

		xx ln -snf ../"${x1:?}" etc/os-release
	done;done
}

##

buildroot_dpn="${PWD:?}"

this_board_dpn="${this_script_dpn:?}"

build_output_fs_target_dpn="${1:-${TARGET_DIR:?missing value for target-directory}}"

[ "${build_output_fs_target_dpn:?}" = "${TARGET_DIR:?}" ]

##

xx pushd "${build_output_fs_target_dpn:?}"

xx :
xx ls -lA
xx ls -lA etc

xx :
xx ls -ld "${init_process_fpn:?}"*

xx :
xx ls -ld usr/lib/os-release*

##

xx :

xx apply_rootfs_overlay_during_post_fakeroot_if_configured "$@" ||
case "$?" in
1)
	xx :

	xx : did not apply overlay -- not configured

	setup_bare_bones_init_process
	;;
*)
	xx :

	xx : did apply overlay -- failed

	false # fail fast
	;;
esac

setup_hostname

setup_os_release_info

setup_login_shell_registry

ensure_rootfs_has_init_process

ensure_systemd_default_target_is multi-user

ensure_linuxrc_does_not_exist_since_it_is_obsolete

remove_post_build_template_files # must be last step, to ensure clean sweep

xx :

