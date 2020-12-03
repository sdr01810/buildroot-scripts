##/bin/bash
## Provides utility functions for working with Debian target architecture monikers.
## 

[ -z "$debian_arch_functions_p" ] || return 0

debian_arch_functions_p=t

debian_arch_debug_p=

##

function as_debian_arch() { # architecture_moniker

	local arch="${1:?missing value for architecture_moniker}"

	local result

	case "${arch:?}" in
	x86_32|x86|i[3456]86])
		result="i386"
		;;
	x86_64|amd64)
		result="amd64"
		;;
	*)
		result="${arch:?}"
		;;
	esac

	echo "${result:?}"
}

function is_supported_debian_arch() { # architecture_moniker

	local arch="${1:?missing value for architecture_moniker}"

        list_architectures_supported_by_debian |

	fgrep -q -x "${arch:?}"
}

function list_architectures_supported_by_debian() {

	local architectures_supported=(

		amd64

		arm64
		armel
		armhf

		i386

		mips
		mips64el
		mipsel

		ppc64el

		s390x
	)
	#^-- correct as of Debian 9 (stretch);
	#^-- source: <https://www.debian.org/distrib/netinst>;
	#^-- source: <https://www.debian.org/releases/stretch/i386/ch02s01.html.en>

	local a1

	for a1 in "${architectures_supported[@]}" ; do
		echo "${a1:?}"
	done
}

