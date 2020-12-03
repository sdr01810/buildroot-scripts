##/bin/bash
## Provides function install_package() and friends.
## 

[ -z "$install_package_functions_p" ] || return 0

install_package_functions_p=t

install_package_debug_p=

##

function install_package() { # [package_name...]

	[ $# -eq 0 ] ||

	(set -x ; sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet --yes install "$@")
}
