function list_call_stack() { #

	local i
	local call_frame_count=0
	local call_frame_count_max=5

	for ((i = 2; i < ${#FUNCNAME[@]}; i++)) ; do

		local line_in_caller=${BASH_LINENO[$(($i - 1))]}

		[[ $((call_frame_count ++)) -lt ${call_frame_count_max} ]] || break

		echo "^-- at line ${line_in_caller:?}; function ${FUNCNAME[$i]:?}; file ${BASH_SOURCE[$i]:?}"
	done |

	sed -e 's/^/    /'
}

