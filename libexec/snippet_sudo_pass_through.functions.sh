function sudo_pass_through() { # ...

	if [ "$(id -u)" -ne 0 ] ; then

		command sudo "$@"
		return $?
	fi

	while [ $# -gt 0 ] ; do
	case "${1}" in
	--)
		shift 1
		;;
	-*|-)
		(unset error ; : "${error:?unsupported sudo(8) option: ${1}}")
		return $?
		;;
	*)
		break
		;;
	esac;done

	"$@"
}
