function reverse_lines() {

	cat "$@" | sed -e 's/^/ x/' | cat -n | sort -rn | sed -e 's/^[^x]*x//'
}
