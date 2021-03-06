#!/usr/bin/env bash
## Install the latest stable buildroot and associated tools.
## 
## Arguments:
##
##     [ --dependencies-only | [--everything] ]
## 
## Typical uses:
##
##     buildroot.install.sh
##     buildroot.install.sh --everything
##     
##     buildroot.install.sh --dependencies-only
##

source "$(dirname "${BASH_SOURCE:?}")"/buildroot-scripts.prolog.sh

source buildroot_api_install.functions.sh

##

function main() { # ...

	xx_buildroot_install "$@"
}

! [ "$0" = "${BASH_SOURCE}" ] || main "$@"
