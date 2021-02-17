sudo_pass_through_real_uid() {

	sudo_pass_through /bin/bash -c 'echo ${SUDO_UID:-$(id -u)}'
}
