#!/bin/bash
## Perform final adjustments to the rootfs target tree before creating each filesystem image.
##
## Arguments:
##
##     target-output-directory
##
## Typical uses:
##
##     buildroot-hook.post-build.sh buildroot-output-main/target
##

set -e

set -o pipefail 2>&- || :

this_script_dpn="$(dirname "${0}")"
this_script_fbn="$(basename "${0}")"

##

true
