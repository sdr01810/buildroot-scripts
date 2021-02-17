sudo_pass_through_real_gid() {

	sudo_pass_through /bin/bash -c 'echo ${SUDO_GID:-$(id -g)}'
}
