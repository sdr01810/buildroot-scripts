#!/bin/bash sourced
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
##     buildroot_rootfs_overlay
##     buildroot_rootfs_overlay --build
##     
##     buildroot_rootfs_overlay --clean-only
##     buildroot_rootfs_overlay --clean-first
##     buildroot_rootfs_overlay --download-only
##     
##     buildroot_rootfs_overlay --run-hook-post-fakeroot
##     buildroot_rootfs_overlay --run-hook-post-fakeroot "${TARGET_DIR:?}"
## 
## Bugs:
## 
##     Only supported for Debian-based build hosts and targets.
## 

[ -z "$buildroot_cli_handler_for_rootfs_overlay_functions_p" ] || return 0

buildroot_cli_handler_for_rootfs_overlay_functions_p=t

buildroot_cli_handler_for_rootfs_overlay_debug_p=

##

source buildroot_api_rootfs_overlay.functions.sh

##

function buildroot_cli_handler_for_rootfs_overlay() { # ...

	load_buildroot_config

	xx_buildroot_rootfs_overlay "$@"
}

