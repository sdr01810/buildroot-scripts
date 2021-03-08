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

source "$(dirname "$0")"/buildroot-hook.prolog.sh

##

for f1 in "${this_script_dpn:?}"/rootfs.post-image.sh ; do

	! [ -e "${f1:?}" ] || "${f1:?}" "$@"
done
