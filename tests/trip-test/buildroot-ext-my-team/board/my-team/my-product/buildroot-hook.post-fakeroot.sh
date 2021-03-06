#!/bin/bash
## Buildroot post-fakeroot script for the target board.
##
## Arguments:
##
##     target-output-directory
##
## Typical uses:
##
##     buildroot-hook.post-fakeroot.sh buildroot-output-main/target
##

source "$(dirname "$0")"/buildroot-hook.prolog.sh

##

for f1 in "${this_script_dpn:?}"/rootfs.post-fakeroot.sh ; do

	! [ -e "${f1:?}" ] || "${f1:?}" "$@"
done
