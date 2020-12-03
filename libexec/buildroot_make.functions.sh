##/bin/bash
## Provides functions that perform special actions provided by the buildroot makefiles.
## 

[ -z "$buildroot_make_functions_p" ] || return 0

buildroot_make_functions_p=t

buildroot_make_debug_p=

##

source buildroot_config.functions.sh

##

function buildroot_make() { # ...

	load_buildroot_config

	xx make "$@"
}

function xx_buildroot_make() {

	buildroot_make "$@"
}

