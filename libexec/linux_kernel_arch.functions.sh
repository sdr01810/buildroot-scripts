##/bin/bash
## Provides utility functions for working with Linux kernel architecture monikers.
## 

[ -z "$linux_kernel_arch_functions_p" ] || return 0

linux_kernel_arch_functions_p=t

linux_kernel_arch_debug_p=

##

function as_linux_kernel_arch() { # architecture_moniker

	local arch="${1:?missing value for architecture_moniker}"

	local result="$(echo "${arch}" | sed -e "s/-.*//" \
		-e s/i.86/i386/ \
		-e s/sun4u/sparc64/ \
		-e s/arcle/arc/ \
		-e s/arceb/arc/ \
		-e s/arm.*/arm/ \
		-e s/sa110/arm/ \
		-e s/aarch64.*/arm64/ \
		-e s/nds32.*/nds32/ \
		-e s/or1k/openrisc/ \
		-e s/parisc64/parisc/ \
		-e s/powerpc64.*/powerpc/ \
		-e s/ppc.*/powerpc/ \
		-e s/mips.*/mips/ \
		-e s/riscv.*/riscv/ \
		-e s/sh.*/sh/ \
		-e s/microblazeel/microblaze/
	)"
	#^-- source: `buildroot-2020.08/Makefile`

	echo "${result:?}"
}

function is_supported_linux_kernel_arch() { # architecture_moniker

	local arch="${1:?missing value for architecture_moniker}"

        list_architectures_supported_by_linux_kernel |

	fgrep -q -x "${arch:?}"
}

function list_architectures_supported_by_linux_kernel() {

	local architectures_supported=(

		alpha
		arc
		arm
		arm64
		c6x
		csky
		h8300
		hexagon
		i386
		ia64
		m68k
		microblaze
		mips
		nds32
		nios2
		openrisc
		parisc
		powerpc
		riscv
		s390
		sh
		sparc
		sparc64
		um
		unicore32
		x86
		x86_64
		xtensa
	)
	#^-- source: `linux-5.4.77/arch/**`

	local a1

	for a1 in "${architectures_supported[@]}" ; do
		echo "${a1:?}"
	done
}

