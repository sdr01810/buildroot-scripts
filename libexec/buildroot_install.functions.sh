##/bin/bash
## Provides function buildroot_install() and friends.
## 

[ -z "$buildroot_install_functions_p" ] || return 0

buildroot_install_functions_p=t

buildroot_install_debug_p=

##

source install_package.functions.sh

source never_mind_optional_package.functions.sh

##

buildroot_artifact_signer_gpg_key_url= # TODO
buildroot_artifact_signer_gpg_key_fingerprint= # TODO

buildroot_version=2020.11.1
buildroot_download_url="https://buildroot.org/downloads"
buildroot_artifact_url="${buildroot_download_url:?}/buildroot-${buildroot_version:?}.tar.gz"
buildroot_artifact_sha1=dc29871b7bd76761db997a7282b9ccbcc78dfcd9 # version-specific

##

function buildroot_install() { # [--everything | --dependencies-only]

	local deps_p=t
	local core_p=t

	while [ $# -gt 0 ] ; do
        case "${1}" in
	--dependencies-only)
		deps_p=t
		core_p=

		shift 1
		;;
	--everything)
		deps_p=t
		core_p=t

		shift 1
		;;
	--)
		shift 1
	        break
		;;
	-*)
		echo 1>&2 "${FUNCNAME:?}: unsupported option: ${1:?}"

		return 2
		;;
	*|'')
		echo 1>&2 "${FUNCNAME:?}: unsupported argument: ${1:?}"

		return 2
		;;
	esac;done

	! [ -n "${deps_p}" ] || buildroot_install_deps

	! [ -n "${core_p}" ] || buildroot_install_core
}

function buildroot_install_core() {

	local buildroot_artifact_fbn="${buildroot_artifact_url##*/}"
	local buildroot_artifact_dbn="${buildroot_artifact_fbn%%.tar*}"
	local buildroot_final_dbn="${buildroot_artifact_dbn%-${buildroot_version:?}}"
	local x1

	if [ -e "${buildroot_final_dbn:?}" -a ! -L "${buildroot_final_dbn:?}" ] ; then

		xx rm -rf "${buildroot_final_dbn:?}"
	fi

	if ! [ -d "${buildroot_artifact_dbn:?}" ] ; then

		if [ ! -s "${buildroot_artifact_fbn:?}" ] ; then

			xx wget -q -O "${buildroot_artifact_fbn:?}" "${buildroot_artifact_url:?}"
			xx echo "${buildroot_artifact_sha1:?} *${buildroot_artifact_fbn:?}" | xx sha1sum --check 
		fi

		xx tar xzf "${buildroot_artifact_fbn:?}"

		rm -f "${buildroot_final_dbn:?}" # force symlink creation below
	fi

	if ! [ "${buildroot_artifact_dbn:?}" = "$(readlink "${buildroot_final_dbn:?}" 2>&- || :)" ] ; then

		xx ln -snf "${buildroot_artifact_dbn:?}" "${buildroot_final_dbn:?}"
	fi

	for x2 in buildroot.env.sample ; do
	for x1 in "${this_script_pkg_root:?}/share/samples/${x2%.sample}" ; do

		if [ -e "${x2%.sample}" ] ; then

			true # user doesn't need a sample
		else
		if [ -e "${x2:?}" ] && cmp --silent "${x1:?}" "${x2:?}" 2>&- ; then

			true # an up-to-date sample is already in place
		else
			xx cp "${x1:?}" "${x2:?}"
		fi;fi
	done
	done
}

function buildroot_install_deps() {

	local packages=(
		bc
		binutils
		bison
		bsdutils # for script(1)
		build-essential
		coreutils
		cmake
		fakechroot
		fakeroot
		flex
		libncurses5-dev
		rsync
		wget
	)

	packages+=(
		python3
		python3-matplotlib
		python3-numpy
		graphviz
	)

	local packages_optional=()

	packages_optional+=( python-is-python3 )

	packages_optional+=( debootstrap qemu-user-static binfmt-support )
	#^-- rootfs overlay creation tools: qemu-debootstrap(8) and friends

	packages_optional+=( libelf-dev libssl-dev )
	#^-- needed to build linux for some target architectures;
	#^-- for example: x86_64 UEFI

	packages_optional+=( initramfs-tools )
	#^-- initrd/initramfs creation tools

	packages_optional+=( live-tools )
	#^-- live CD creation tools

	local commands_expected=(
		bash
		bc
		bison
		bzip2
		cpio
		fakechroot
		fakeroot
		file
		flex
		g++
		gcc
		gpg
		gzip
		make
		patch
		perl
		rsync
		sed
		sha1sum
		tar
		unzip
		which
	)

	local x1 xc

	install_package "${packages[@]}"

	for x1 in "${packages_optional[@]}" ; do
		install_package "${x1:?}" || never_mind_optional_package
	done

	for x1 in "${commands_expected[@]}" ; do
		if ! hash "${x1:?}" >/dev/null 2>&1 ; then
			xc=$? ; echo 1>&2 "${FUNCNAME:?}: missing required command: ${x1:?}"
		fi
	done

	return ${xc:-0}
}

function xx_buildroot_install() {

	buildroot_install "$@"
}

function xx_buildroot_install_deps() {

	buildroot_install_deps "$@"
}

function xx_buildroot_install_core() {

	buildroot_install_core "$@"
}

