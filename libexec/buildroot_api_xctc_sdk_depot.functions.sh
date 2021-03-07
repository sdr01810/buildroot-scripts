#!/bin/bash sourced
##

[ -z "$buildroot_xctc_sdk_depot_functions_p" ] || return 0

buildroot_xctc_sdk_depot_functions_p=t

buildroot_xctc_sdk_depot_debug_p=

##

source snippet_reverse_lines.functions.sh

##

function buildroot_xctc_sdk_package_name_from_depot_type() { # depot_type

	local depot_type=${1:?missing value for depot_type} ; shift 1

	local result=

	case "${depot_type:?}" in
	package_archive)
		result=buildroot-xctc
		;;
	download_cache)
		result=toolchain-external-custom
		;;
	*)
		echo 1>&2 "${FUNCNAME:?}: unrecognized/unsupported depot type: ${depot_type:?}"
		return 2
		;;
	esac

	echo "${result}"
}

function register_buildroot_xctc_sdk_with_depot() { # depot_type depot_root xctc_build_output_root

	local depot_type=${1:?missing value for depot_type} ; shift 1

	local depot_root=${1:?missing value for depot_root} ; shift 1

	local xctc_build_output_root=${1:?missing value for xctc_build_output_root} ; shift 1

	local xctc_sdk_package_name
	xctc_sdk_package_name=$(buildroot_xctc_sdk_package_name_from_depot_type "${depot_type:?}")

	local d1 d2
	local x1 x2

	for d1 in "${xctc_build_output_root:?}"/images ; do
	for d2 in "${depot_root:?}/${xctc_sdk_package_name:?}" ; do

		for x1 in "${d1:?}"/*_sdk* ; do
		for x2 in "${d2:?}/${x1#${d1:?}/}" ; do

			[[ -e ${x1:?} ]] || continue

			[[ -e ${d2:?} ]] || (xx : && xx mkdir -p "${d2:?}")

			xx : && xx rsync -a -i -c "${x1:?}" "${x2:?}"

			#^-- FIXME: what if someone is downloading during the rsync? safe?
		done;done
	done;done
}

function withdraw_buildroot_xctc_sdk_from_depot() { # depot_type depot_root xctc_build_output_root

	local depot_type=${1:?missing value for depot_type} ; shift 1

	local depot_root=${1:?missing value for depot_root} ; shift 1

	local xctc_build_output_root=${1:?missing value for xctc_build_output_root} ; shift 1

	local xctc_sdk_package_name
	xctc_sdk_package_name=$(buildroot_xctc_sdk_package_name_from_depot_type "${depot_type:?}")

	local d1 d2
	local x1 x2

	for d1 in "${xctc_build_output_root:?}"/images ; do
	for d2 in "${depot_root:?}/${xctc_sdk_package_name:?}" ; do

		for x1 in "${d1:?}"/*_sdk* ; do
		for x2 in "${d2:?}/${x1#${d1:?}/}" ; do

			[[ -e ${d2:?} && -e ${x1:?} ]] || continue

			xx : && xx rm -rf "${x2:?}"

			#^-- FIXME: what if someone is downloading during the removal? safe?
		done;done
	done;done
}

function trigger_download_of_buildroot_xctc_sdk_on_next_build_within() { # main_build_output_root

	local main_build_output_root=${1:?missing value for main_build_output_root} ; shift 1

	local xctc_sdk_package_name
	xctc_sdk_package_name=$(buildroot_xctc_sdk_package_name_from_depot_type download_cache)

	local d1 d2

	for d1 in "${main_build_output_root:?}" ; do
	for d2 in "${d1:?}/build/${xctc_sdk_package_name:?}" ; do

		[[ -e ${d2:?} ]] || continue

		xx : && xx rm -rf "${d2:?}"/.stamp_downloaded
	done;done
}

##

function get_buildroot_xctc_sdk_tarball() { # [ --image ] [ --pa ] [ --dl ]

	local arg build_image_p package_archive_p download_cache_p

	local tarball_fbn="x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz"
	#^-- FIXME: compute based on buildroot config; do not hardcode

	for arg in "${@:---image}" ; do case "${arg}" in
	--image)
		build_image_p=t
		;;
	--pa)
		package_archive_p=t
		;;
	--dl)
		download_cache_p=t
		;;
	'')
		echo 1>&2 "${FUNCNAME:?}: empty argument"
		return 2
		;;
	*)
		echo 1>&2 "${FUNCNAME:?}: invalid argument: ${arg:?}"
		return 2
		;;
	esac;done

	! [[ -n ${build_image_p} ]] ||
	"${FUNCNAME:?}"_1 "${BR2_ENV_OUTPUT_XCTC_DIR:?}/images/${tarball_fbn:?}"

	! [[ -n ${package_archive_p} ]] ||
	"${FUNCNAME:?}"_1 "${BR2_ENV_DL_PTB_DIR:?}/$(buildroot_xctc_sdk_package_name_from_depot_type package_archive)/${tarball_fbn:?}"

	! [[ -n ${download_cache_p} ]] ||
	"${FUNCNAME:?}"_1 "${BR2_ENV_DL_PTB_DIR:?}/$(buildroot_xctc_sdk_package_name_from_depot_type download_cache)/${tarball_fbn:?}"
}

function get_buildroot_xctc_sdk_tarball_1() { # tarball_fpn

	local tarball_fpn=${1:?missing value for tarball_fpn} ; shift 1

	if [[ -f ${tarball_fpn:?} && -s ${tarball_fpn:?} ]] ; then

		echo "${tarball_fpn:?}"
	fi
}

function remove_buildroot_xctc_sdk_tarball() { # [ --image ] [ --pa ] [ --dl ]

	local f1 f_count=0

	get_buildroot_xctc_sdk_tarball "${@:---image}" | reverse_lines |

	while read -r f1 ; do

		! [[ $((f_count ++)) -eq 0 ]] || xx :

		xx rm -f "${f1:?}"
	done
}

