##/bin/bash
## Source'd at the beginning of all scripts in this installation set.
## 

set -e

set -o pipefail 2>&- || :

##

this_script_fpn="$(realpath "${BASH_SOURCE[1]}")"

this_script_dpn="$(dirname "${this_script_fpn:?}")"
this_script_fbn="$(basename "${this_script_fpn:?}")"

this_script_pkg_root="$(dirname "${this_script_dpn%/thunk}")"

PATH="${this_script_pkg_root:?}/bin:${this_script_pkg_root:?}/bin/thunk:${this_script_pkg_root:?}/libexec${PATH:+:${PATH}}"

##

source xx.functions.sh

##

