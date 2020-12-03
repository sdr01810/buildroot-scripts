#!/bin/bash
## Buildroot post-image script for the target board.
##
## Arguments:
##
##     binaries-output-directory
##
## Typical uses:
##
##     buildroot-hook.post-image.sh buildroot-output-main/images
##

set -e

set -o pipefail 2>&- || :

this_script_dpn="$(dirname "${0}")"
this_script_fbn="$(basename "${0}")"

##

for f1 in "${this_script_dpn:?}"/rootfs.post-image.sh ; do

	! [ -e "${f1:?}" ] || "${f1:?}" "$@"
done
