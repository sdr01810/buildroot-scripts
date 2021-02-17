##/bin/bash
## Provides utility functions for working with tests written as shell scripts.
## 

[ -z "$test_functions_p" ] || return 0

test_functions_p=t

test_debug_p=

##

source assert.functions.sh

##

function expect_xc() { # expected_exit_code command [command_arg ...]

	assert_xc "$@"
}
