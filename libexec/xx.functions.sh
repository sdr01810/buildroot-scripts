##/bin/bash
## Provides function xx() and friends.
## 

[ -z "$xx_functions_p" ] || return 0

xx_functions_p=t

xx_debug_p=

##

function xx() { # ...

	xx_lod "" "$@"
}

function xx_lod() { # this_lod ...
##
## Execute the specified command as if `set -x` could automatically go into
## effect at a specified level of detail.
##
## More precisely, environment variable `XX_LOD_THRESHOLD` governs whether
## the equivalent of `set -x` is in effect. It will be in effect only when
## `${XX_LOD_THRESHOLD}` is at least `${this_lod}`.
## 
## Net result: when `${XX_LOD_THRESHOLD}` is at least `${this_lod}`, the
## command is first echoed to stderr with a suitable prefix. Then,
## regardless of `XX_LOD_THRESHOLD`, the command is invoked.
## 
## As for `set -x` itself, the prefix is governed by `PS4` (default `'+'`).
## 
## Note that both `XX_LOD_THRESHOLD` and `this_lod` default to 1. So, if
## you want the `set -x` effect at the normal level of detail, you're all
## set; if you want to disable the effect entirely, set `XX_LOD_THRESHOLD`
## to 0; and if you want it only at higher levels of detail, set it to the
## desired threshold.
##
	local default_lod="1" ; local this_lod="${1:-${default_lod:?}}" ; shift 1

	if [ "${XX_LOD_THRESHOLD:-${default_lod:?}}" -ge "${this_lod:?}" ] ; then

		echo 1>&2 "${PS4:-+}" "$@"
	fi

	"$@"
}

##
