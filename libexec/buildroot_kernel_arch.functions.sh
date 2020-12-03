##/bin/bash
## Provides utility functions for working with buildroot kernel architecture monikers.
## 

[ -z "$buildroot_kernel_arch_functions_p" ] || return 0

buildroot_kernel_arch_functions_p=t

buildroot_kernel_arch_debug_p=

##

source linux_kernel_arch.functions.sh

##

function as_buildroot_kernel_arch() { # architecture_moniker

	as_linux_kernel_arch "$@"
}

function is_supported_buildroot_kernel_arch() { # architecture_moniker

	is_supported_linux_kernel_arch "$@"
}

function list_architectures_supported_by_buildroot_kernel() {

	list_architectures_supported_by_linux_kernel "$@"
}

