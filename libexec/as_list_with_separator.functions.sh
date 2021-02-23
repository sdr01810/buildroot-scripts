##/bin/bash
## Provides function as_list_with_separator() and friends.
## 

[ -z "$as_list_with_separator_functions_p" ] || return 0

as_list_with_separator_functions_p=t

as_list_with_separator_debug_p=

##

source omit_wsac.functions.sh

##

function args_as_list_with_separator() { # separator [element ...]

	as_list_with_separator "$@"
}

function as_list_with_separator() { # separator [element ...]

	local separator="${1:?missing value for separator}" ; shift 1

	local elements=( "$@" ) ; shift $#

	local result e1

	for e1 in "${elements[@]}" ; do

		result="${result:+${result:?}${separator:?}}${e1:?}"
	done

	echo "${result}"
}

function file_contents_as_list_with_separator() { # separator [file_pn ...]

	local separator="${1:?missing value for separator}" ; shift 1

	local files=( "$@" ) ; shift $#

	[ $# -eq 0 ]

	local separator_quoted="$(printf %q "${separator:?}")"

	local result f1

	for f1 in "${files[@]}" ; do

		local f1_contents_as_list_fragments=( $(omit_wsac "${f1:?}") )

		local f1_contents_as_list="$(as_list_with_separator "${separator:?}" "${f1_contents_as_list_fragments[@]}")"

		result="${result:+${result:?}${separator:?}}${f1_contents_as_list}"
	done

	echo "${result}"
}

