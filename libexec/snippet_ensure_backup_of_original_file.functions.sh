##/bin/bash
## Provides function ensure_backup_of_original_file() and friends.
## 

[ -z "$ensure_backup_of_original_file_functions_p" ] || return 0

ensure_backup_of_original_file_functions_p=t

ensure_backup_of_original_file_debug_p=

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

