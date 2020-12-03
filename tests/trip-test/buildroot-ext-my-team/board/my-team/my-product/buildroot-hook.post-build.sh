#!/bin/bash
## Buildroot post-build script for the target board.
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

for f1 in "${this_script_dpn:?}"/rootfs.post-build.sh ; do

	! [ -e "${f1:?}" ] || "${f1:?}" "$@"
done
