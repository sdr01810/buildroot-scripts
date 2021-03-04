##/bin/bash
## Provides function install_package() and friends.
## 

[ -z "$install_package_functions_p" ] || return 0

install_package_functions_p=t

install_package_debug_p=

##

function install_package() { # [package_name...]

	if [ $# -gt 0 ] ; then
	(
		## for environment variable settings:
		## <https://wiki.debian.org/Multistrap/Environment>

		export DEBCONF_NONINTERACTIVE_SEEN=true
		export DEBIAN_FRONTEND=noninteractive

		export LC_ALL=C LANGUAGE=C LANG=C

		sudo_pass_through apt-get --quiet --yes install "$@"
	)
	fi
}
