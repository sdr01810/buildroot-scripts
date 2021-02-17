##/bin/bash
## Provides function omit_wsac() and friends.
## 

[ -z "$omit_wsac_functions_p" ] || return 0

omit_wsac_functions_p=t

omit_wsac_debug_p=

##

function omit_wsac() { # args like cat(1)

	cat "$@" | (egrep -v '^\s*(#|$)' || :)
}

