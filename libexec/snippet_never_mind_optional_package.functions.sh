##/bin/bash
## Provides function never_mind_optional_package() and friends.
## 

[ -z "$never_mind_optional_package_functions_p" ] || return 0

never_mind_optional_package_functions_p=t

never_mind_optional_package_debug_p=

##

function never_mind_optional_package() {

	echo 1>&2 "^-- package is not required; continuing without it..."
}
