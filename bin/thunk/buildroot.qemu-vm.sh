#!/bin/bash
## Manage running a QEMU VM using outputs from a buildroot-based build.
## 
## Arguments:
##
##     --run [ --using-boot-disk | [ --using-initrd ] ]
## 
## Typical uses:
## 
##     buildroot.qemu-vm.sh
##     buildroot.qemu-vm.sh --run
##     buildroot.qemu-vm.sh --run --using-initrd
##     
##     buildroot.qemu-vm.sh --run --using-boot-disk
## 

source "$(dirname "${BASH_SOURCE:?}")"/buildroot-scripts.prolog.sh

source buildroot_qemu_vm.functions.sh

##

function main() { # ...

	load_buildroot_config

	xx_buildroot_qemu_vm "$@"
}

! [ "$0" = "${BASH_SOURCE}" ] || main "$@"
