#!/bin/bash
## Perform final actions now that all rootfs filesystem image(s) have been made.
##
## Arguments:
##
##     binaries-output-directory
##
## Inherited from parent (buildroot post-image) environment:
##
##     BINARIES_DIR
##
## Typical uses:
##
##     buildroot-hook.post-image.sh buildroot-output-main/images
##

source "$(dirname "$0")"/buildroot-hook.prolog.sh

##

for f1 in "${this_script_dpn:?}"/boot-disk.create.sh ; do

	[ -e "${BINARIES_DIR:?}"/rootfs.ext2 ] || continue

	[ -e "${f1:?}" ] || continue

	"${f1:?}" "$@"
done
