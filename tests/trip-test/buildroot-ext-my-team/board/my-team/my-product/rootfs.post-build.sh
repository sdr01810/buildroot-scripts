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

source "$(dirname "$0")"/buildroot-hook.prolog.sh

##

true
