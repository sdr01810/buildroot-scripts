##/bin/bash
## Provides function buildroot_qemu_vm() and friends.
## 

[ -z "$buildroot_qemu_vm_functions_p" ] || return 0

buildroot_qemu_vm_functions_p=t

buildroot_qemu_vm_debug_p=

##

source buildroot_api_config.functions.sh

##

function buildroot_qemu_vm() { # [--run] ...

	local action="${1:---run}"
        ! [ $# -ge 1 ] || shift 1

        case "${action:?}" in
	--run)
		true
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unsupported buildroot qemu-vm action: ${action}"
		return 2
		;;
	esac

	xx_buildroot_qemu_vm_run "$@"
}

function buildroot_qemu_vm_run() { # [--using-boot-disk|--using-initrd]

	local method="${1:---using-initrd}"
        ! [ $# -ge 1 ] || shift 1

	local qemu_system_cmd=(
		"qemu-system.sh"
	)

	local qemu_system_opts=(
		-enable-kvm
		-m 1g,maxmem=2g
		-device qxl-vga
		-device qemu-xhci
		-device usb-mouse
		-device usb-tablet
	)

	local x1

	if ! hash "${qemu_system_cmd:?}" 2>&- ; then

		qemu_system_cmd=(

			env PATH="$(dirname "${BASH_SOURCE:?}")${PATH:+:${PATH:?}}" "${qemu_system_cmd[@]}"
		)
	fi

        case "${method:?}" in
	--using-boot-disk)
		for x1 in "${BR2_ENV_OUTPUT_DIR:?}"/images/boot-disk.img ; do

			qemu_system_opts+=( -bios /usr/share/qemu/OVMF.fd -drive index=0,format=raw,file="${x1:?}" )
		done
		;;
	--using-initrd)
		for x1 in "${BR2_ENV_OUTPUT_DIR:?}"/images/rootfs.cpio ; do
		for x2 in "${BR2_ENV_OUTPUT_DIR:?}"/images/bzImage ; do

			qemu_system_opts+=( -initrd "${x1:?}" -kernel "${x2:?}" )
		done;done
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unsupported buildroot qemu-vm run method: ${method}"
		return 2
		;;
	esac

	xx "${qemu_system_cmd[@]}" "${qemu_system_opts[@]}" "$@"
}

function xx_buildroot_qemu_vm() { # ...

	buildroot_qemu_vm "$@"
}

function xx_buildroot_qemu_vm_run() { # ...

	buildroot_qemu_vm_run "$@"
}

