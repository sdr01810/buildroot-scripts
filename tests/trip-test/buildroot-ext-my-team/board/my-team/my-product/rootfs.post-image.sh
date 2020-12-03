#!/bin/bash
## Perform final actions now that all rootfs filesystem image(s) have been made.
##
## Arguments:
##
##     binaries-output-directory
##
## Inherited from parent (buildroot post-fakeroot) environment:
##
##     BINARIES_DIR
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

for f1 in "${this_script_dpn:?}"/boot-disk.create.sh ; do

	[ -e "${BINARIES_DIR:?}"/rootfs.ext2 ] || continue

	[ -e "${f1:?}" ] || continue

	"${f1:?}" "$@"
done
