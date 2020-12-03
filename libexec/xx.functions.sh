##/bin/bash
## Provides function xx() and friends.
## 

[ -z "$xx_functions_p" ] || return 0

xx_functions_p=t

xx_debug_p=

##

function xx() { # ...
##
## Execute specified command as if `set -x` is in effect.
## 
## Net result: the command is first echoed to stderr with a suitable
## prefix, and then it is invoked.
##
	echo 1>&2 "${PS4:-+}" "$@"

	"$@"
}

function xx_env() { # ...
##
## Apply `/usr/bin/env` to the specified command as if `set -x` is in effect.
## 
## Net result: the command is first echoed to stderr with a suitable
## prefix, and then it is invoked via `/usr/bin/env`.
##
	echo 1>&2 "${PS4:-+}" /usr/bin/env "$@"

	/usr/bin/env "$@"
}

function xx_eval() { # ...
##
## Apply `eval` to the specified command as if `set -x` is in effect.
## 
## Net result: the command is first echoed to stderr with a suitable
## prefix, and then it is eval'ed.
##
	echo 1>&2 "${PS4:-+}" eval "$@"

	eval "$@"
}
