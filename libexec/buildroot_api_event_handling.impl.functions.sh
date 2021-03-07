#!/bin/bash sourced
## Provides the default implementation of the buildroot event handling API.
## 

[ -z "$buildroot_event_handling_impl_functions_p" ] || return 0

buildroot_event_handling_impl_functions_p=t

buildroot_event_handling_impl_debug_p=

##

function handle_buildroot_event_of_type_any__impl_default() { # caller_function_name stamped_event_detail ...

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	log_buildroot_event "$@"
}

function handle_buildroot_event_of_type_package__impl_default() { # caller_function_name stamped_event_detail ...

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	"${FUNCNAME/%_package*}"_any__impl_default "${FUNCNAME:?}" "$@"

	snapshot_output_manifest_for_buildroot_event "$@"
}

function handle_raw_buildroot_event_of_type__impl_default() { # caller_function_name event_type [ raw_event_detail ... ]

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	handle_buildroot_event $(get_stamped_details_from_raw_buildroot_event_of_type "$@")
}

function select_log_files_for_buildroot_event__impl_default() { # caller_function_name stamped_event_detail ...

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	local event_stamp event_type result

	event_stamp=${1:?missing value for event_stamp}

	event_type=${2:?missing value for event_type}

	result=${BUILD_DIR:?}.event.log

	echo "${result}"
}

function snapshot_output_manifest_for_buildroot_event_of_type_package__impl_default() { # caller_function_name stamped_event_detail ...

	local caller_function_name=${1:?missing value for caller_function_name} ; shift 1

	local event_stamp event_type package_name step_name edge_name

	event_stamp=${1:?missing value for event_stamp}

	event_type=${2:?missing value for event_type}

	package_name=${3:?missing value for package_name}

	step_name=${4:?missing value for step_name}

	edge_name=${5:?missing value for edge_name}

	local result_file_stem

	result_file_stem=$(get_file_name_words_from_buildroot_event "$@")
	result_file_stem=${result_file_stem// /.}

	local affected_output_dir_pn

	case "${step_name:?}" in
	install-host)
		affected_output_dir_pn=${HOST_DIR}
		;;
	install-staging)
		affected_output_dir_pn=${STAGING_DIR}
		;;
	install-target)
		affected_output_dir_pn=${TARGET_DIR}
		;;
	install-*)
		# unrecognized/unsupported; ignore
		;;
	*)
		# do not snapshot source tree(s) per package step: too slow; not useful
		;;
	esac

	local result_file_parent_pn=${BASE_DIR:?}/build.manifests.d

	local result_file_pn=${result_file_parent_pn:?}/${result_file_stem:?}.files

	local snapshotting_enabled_flag_fpn=${result_file_parent_pn%.d}.ENABLED

	if [[ -n ${affected_output_dir_pn} && -e ${snapshotting_enabled_flag_fpn:?} ]] ; then

		local affected_output_dir_rpn=${affected_output_dir_pn#${BASE_DIR:?}/}

		echo 1>&2
		echo 1>&2 "${this_script_name:?}: snapshotting output manifest: ${package_name:?} ${step_name:?} ${edge_name:?} ..."

		mkdir -p "${result_file_parent_pn:?}"

		(cd "${BASE_DIR:?}" &&

			! [[ -e ${affected_output_dir_rpn:?} ]] ||

			find -H "${affected_output_dir_rpn:?}"

		) | LC_ALL=C sort -u > "${result_file_pn:?}"

		echo 1>&2
	fi
}

