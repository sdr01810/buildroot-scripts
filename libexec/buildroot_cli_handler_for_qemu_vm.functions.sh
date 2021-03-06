#!/bin/bash sourced
## Manage running a QEMU VM using outputs from a buildroot-based build.
## 
## Arguments:
##
##     --run [ --using-boot-disk | [ --using-initrd ] ]
## 
## Typical uses:
## 
##     buildroot_qemu_vm
##     buildroot_qemu_vm --run
##     buildroot_qemu_vm --run --using-initrd
##     
##     buildroot_qemu_vm --run --using-boot-disk
## 

[ -z "$buildroot_cli_handler_for_qemu_vm_functions_p" ] || return 0

buildroot_cli_handler_for_qemu_vm_functions_p=t

buildroot_cli_handler_for_qemu_vm_debug_p=

##

source buildroot_api_qemu_vm.functions.sh

##

function buildroot_cli_handler_for_qemu_vm() { # ...

	load_buildroot_config

	buildroot_qemu_vm "$@"
}

