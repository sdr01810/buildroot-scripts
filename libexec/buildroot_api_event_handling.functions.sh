#!/bin/bash sourced
## Provides utility functions for processing buildroot events.
## 

[ -z "$buildroot_event_handling_functions_p" ] || return 0

buildroot_event_handling_functions_p=t

buildroot_event_handling_debug_p=

##

source "${BASH_SOURCE%.*.sh}".impl.functions.sh

##

function get_buildroot_event_stamp() { #

	local result

	result=$(date --rfc-3339=ns)

	result="${result%[-+]??:??} ${result##*.?????????}"  # YYYY-MM-DD HH:mm:ss.nnnnnnnnn-ZZ:zz --> ...
	result="${result// /;}"                              # ... --> YYYY-MM-DD;HH:mm:ss.nnnnnnnnn;-ZZ:zz

	echo "${result}"
}

function get_file_name_words_from_buildroot_event_stamp() { # event_stamp

	local result

	result=${1:?missing value for event_stamp} ; shift 1

	result="${result/-/}"
	result="${result/-/}"

	result="${result/;/-}"

	result="${result/./-}"

	result="${result//;/}"

	result="${result//:/}"

	echo "${result}"
}

function get_file_name_words_from_buildroot_event() { # stamped_event_detail ...

	local event_stamp event_type result

	event_stamp=${1:?missing value for event_stamp} ; shift 1

	event_type=${1:?missing value for event_type} ; shift 1

	result=$(get_file_name_words_from_buildroot_event_stamp "${event_stamp:?}")

	result="${result:?} ${event_type:?}${@:+ }${@}"

	echo "${result}"
}

function get_stamped_details_from_raw_buildroot_event_of_type() { # event_type [ raw_event_detail ... ]

	local event_stamp event_type result=()

	event_stamp=$(get_buildroot_event_stamp)

	event_type=${1:?missing value for event_type} ; shift 1

	result+=( "${event_stamp:?}" "${event_type:?}" )

	case "${event_type:?}" in
	package)
		# in order of increasing change frequency:
		result+=( "${3:?missing value for package_name}" )
		result+=( "${2:?missing value for step_name}" )
		result+=( "${1:?missing value for edge_name}" )

		shift 3
		;;
	esac

	result+=( "$@" ) ; shift $#

	echo "${result[@]}"
}

function handle_buildroot_event() { # stamped_event_detail ...

	local event_stamp event_type delegate

	event_stamp=${1:?missing value for event_stamp}

	event_type=${2:?missing value for event_type}

	delegate="${FUNCNAME:?}_of_type_${event_type:?}"

	if [[ $(type -t "${delegate:?}") == function ]] ; then

		"${delegate}" "$@"
	fi
}

function handle_buildroot_event_of_type_any() { # stamped_event_detail ...

	"${FUNCNAME:?}"__impl_default "${FUNCNAME:?}" "$@"
}

function handle_buildroot_event_of_type_package() { # stamped_event_detail ...

	"${FUNCNAME:?}"__impl_default "${FUNCNAME:?}" "$@"
}

function handle_raw_buildroot_event_of_type() { # event_type [ raw_event_detail ... ]

	"${FUNCNAME:?}"__impl_default "${FUNCNAME:?}" "$@"
}

function log_buildroot_event() { # stamped_event_detail ...

	local event_stamp event_type log_entry log_file_pn

	event_stamp=${1:?missing value for event_stamp} ; shift 1

	event_type=${1:?missing value for event_type} ; shift 1

	select_log_files_for_buildroot_event "$@" |

	while read -r log_file_pn ; do

		log_entry="${event_stamp//;/ } ${event_type}${@:+ }${@}"

		echo "${log_entry}" >> "${log_file_pn:?}"
	done
}

function select_log_files_for_buildroot_event() { # stamped_event_detail ...

	"${FUNCNAME:?}"__impl_default "${FUNCNAME:?}" "$@"
}

function snapshot_output_manifest_for_buildroot_event() { # stamped_event_detail ...

	local event_stamp event_type delegate

	event_stamp=${1:?missing value for event_stamp}

	event_type=${2:?missing value for event_type}

	delegate="${FUNCNAME:?}_of_type_${event_type:?}"

	if [[ $(type -t "${delegate:?}") == function ]] ; then

		"${delegate}" "$@"
	fi
}

function snapshot_output_manifest_for_buildroot_event_of_type_package() { # stamped_event_detail ...

	"${FUNCNAME:?}"__impl_default "${FUNCNAME:?}" "$@"
}

