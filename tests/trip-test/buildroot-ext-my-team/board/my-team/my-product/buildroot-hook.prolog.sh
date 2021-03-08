#!/bin/bash sourced
## Source'd at the beginning of all buildroot hook scripts in this set.
##

set -e

set -o pipefail || :

##

this_script_fpn=$(realpath -s "${BASH_SOURCE[1]}")

this_script_dpn=$(dirname "${this_script_fpn:?}")
this_script_fbn=$(basename "${this_script_fpn:?}")

this_script_name=${this_script_fbn%.*sh}

##

