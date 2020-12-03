#!/bin/bash
## Invoke make(1) for a buildroot-based build.
## 
## Arguments:
## 
##     [ <any-make-arg> ... ]
## 
## Typical uses:
##
##     buildroot.make.sh
##     buildroot.make.sh all
##     
##     buildroot.make.sh clean
## 

source "$(dirname "${BASH_SOURCE:?}")"/buildroot-scripts.prolog.sh

source buildroot_make.functions.sh

##

function main() { # ...

	xx_buildroot_make "$@"
}

! [ "$0" = "${BASH_SOURCE}" ] || main "$@"
