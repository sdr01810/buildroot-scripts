#!/bin/bash
## Manage the root filesystem overlay generated for a buildroot-based build.
## 
## Arguments:
##
##     --clean-only 
## 
##     [ --build ] [ --clean-first | --download-only ]
## 
##     --run-hook-post-fakeroot [ <buildroot_output_fs_target_dir> ]
## 
## Typical uses:
##
##     buildroot.rootfs-overlay.sh
##     buildroot.rootfs-overlay.sh --build
##     
##     buildroot.rootfs-overlay.sh --clean-only
##     buildroot.rootfs-overlay.sh --clean-first
##     buildroot.rootfs-overlay.sh --download-only
##     
##     buildroot.rootfs-overlay.sh --run-hook-post-fakeroot
##     buildroot.rootfs-overlay.sh --run-hook-post-fakeroot "${TARGET_DIR:?}"
## 
## Bugs:
## 
##     Only supported for Debian-based build hosts and targets.
## 

source "$(dirname "${BASH_SOURCE:?}")"/../../libexec/buildroot_cli.prolog.sh

source buildroot_api_rootfs_overlay.functions.sh

##

function main() { # ...

	load_buildroot_config

	xx_buildroot_rootfs_overlay "$@"
}

! [ "$0" = "${BASH_SOURCE}" ] || main "$@"

