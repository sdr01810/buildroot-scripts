##/bin/bash
## Provides function buildroot_trip_test() and friends.
## 

[ -z "$buildroot_trip_test_functions_p" ] || return 0

buildroot_trip_test_functions_p=t

buildroot_trip_test_debug_p=

##

source assert.functions.sh

source test.functions.sh

##

source buildroot_config.functions.sh

##

function buildroot_trip_test() { # ...

	local action=
	local action_args=()
	local clean_all_p=

	while [ $# -gt 0 ] ; do
        case "${1}" in
	--run)
		action="${action:-run}"
		[ "${action:?}" = "run" ]

		shift 1
		;;
	--clean-only)
		action="${action:-clean}"
		[ "${action:?}" = "clean" ]

		clean_all_p=t

		shift 1
		;;
	--clean-first)
		action="${action:-run}"
		[ "${action:?}" = "run" ]

		clean_all_p=t

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
		break
		;;
	esac;done

	: "${action:=run}"

	action_args+=( "$@" ) ; shift $#

	##

	unset_buildroot_config

        if [[ -n ${clean_all_p} ]] ; then

		xx_buildroot_trip_test_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"xx_buildroot_trip_test_${action:-run}" "${action_args[@]}"
	fi
}

function buildroot_trip_test_run() { # [ starting_state ]

	local starting_state=${1:-0} ; shift 1 || :

	local current_state=${starting_state:?}

	while [[ -n ${current_state} &&  ${current_state:?} != done ]] ; do

		current_state=$("${FUNCNAME:?}"_1 "${current_state:?}") || break
	done

	if [[ "${current_state}" != done ]] ; then

		echo 1>&2
		echo 1>&2 "^-- ${this_script_fbn:?}: FAIL"
	else
		echo 1>&2
		echo 1>&2 "^-- ${this_script_fbn:?}: PASS"
	fi		
}

function buildroot_trip_test_run_1() { # [state]

	local state="${1:-0}" ; shift 1 || :

	declare -A state_indexes_by_name_or_index=(

		[0]=0    [start]=0

		[1]=1    [install]=1

		[2]=2    [xctc-config]=2

		[3]=3    [main-config]=3

		[4]=4    [xctc-build]=4

		[5]=5    [rol-build]=5

		[6]=6    [main-build]=6

		[7]=7    [preserve-all-outputs]=7

		[8]=8    [main-clean]=8

		[9]=9    [rol-clean]=9

		[10]=10  [xctc-clean]=10

		[11]=11  [finish]=11
	)

	declare -A state_replacements_by_index=(

#!#		[${state_indexes_by_name_or_index[install]:?}]=finish # FIXME: debug

		#^-- used when debugging; otherwise empty
	)

	local d1 f1

	local result=

	state=${state_indexes_by_name_or_index[${state:?}]}

	if [[ -n ${state_replacements_by_index[${state:?}]} ]] ; then

		state=${state_replacements_by_index[${state:?}]}
	fi

	case "${state:?}" in
	0|start)

		expect_xc 0 buildroot_trip_test_clean || return $?
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -n "$(ls -d buildroot*.tar.gz 2>&- | head -1)" || return $?
		expect_xc 0 test ! -d buildroot-output-xctc || return $?
		expect_xc 0 test ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot || return $?
		;;

	1|install)

		expect_xc 2 buildroot.sh install --bad-option || return $?
		expect_xc 0 test ! -d buildroot || return $?

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		expect_xc 0 buildroot.sh install --everything || return $?
		expect_xc 0 test -d buildroot -a -n "$(sudo which debootstrap)" || return $?

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		expect_xc 0 buildroot.sh install --dependencies-only || return $?
		expect_xc 0 test ! -d buildroot -a -n "$(sudo which debootstrap)" || return $?

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		expect_xc 0 buildroot.sh install 
		expect_xc 0 test -d buildroot -a -n "$(sudo which debootstrap)" || return $?
		;;

	2|xctc-config)

		# TODO: place xctc-config tests here
		;;

	3|main-config)

		# TODO: place main-config tests here
		;;

	4|xctc-build)

		expect_xc 1 buildroot.sh --output-main toolchain || return $?
		expect_xc 0 test ! -d buildroot-dl-ptb -a ! -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		expect_xc 1 buildroot.sh --output-main sdk || return $?
		expect_xc 0 test ! -d buildroot-dl-ptb -a ! -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		expect_xc 1 buildroot.sh --output-xctc my_team_product_x86_64_main_defconfig || return $?
		expect_xc 0 test ! -d buildroot-dl-ptb -a ! -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		expect_xc 0 buildroot.sh --output-xctc my_team_product_x86_64_xctc_defconfig || return $?
		expect_xc 0 test ! -d buildroot-dl-ptb -a   -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh --output-xctc toolchain || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh --output-xctc sdk || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh --output-xctc || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh --output-xctc all || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh toolchain || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh sdk || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		;;

	5|rol-build)

		expect_xc 2 buildroot.sh rootfs-overlay --bad-option || return $?
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 1 buildroot.sh rootfs-overlay --build --clean-only || return $?
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 1 buildroot.sh rootfs-overlay --build --clean-first --clean-only || return $?
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 1 buildroot.sh rootfs-overlay --clean-first --clean-only || return $?
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh rootfs-overlay --download-only || return $?
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh my_team_product_x86_64_main_defconfig || return $?
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh rootfs-overlay --download-only || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh rootfs-overlay --build --download-only || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh rootfs-overlay --build --clean-first || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar || return $?

		xx :
		xx sudo rm -rf buildroot-output-rol

		expect_xc 0 buildroot.sh rootfs-overlay --build || return $?
		expect_xc 0 test -d buildroot-dl-rol -a ! -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar || return $?

		xx :
		xx sudo rm -rf buildroot-output-rol.tar

		expect_xc 0 buildroot.sh rootfs-overlay --build || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh rootfs-overlay --clean-first || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar || return $?

		expect_xc 0 buildroot.sh rootfs-overlay || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar || return $?
		;;

	6|main-build)

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -rf buildroot-dl-ptb/toolchain-external-custom

		expect_xc 0 buildroot.sh toolchain{,-external{,-custom}}-dirclean || return $?

		xx :
		xx mv -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz{,.ASIDE}

		expect_xc 0 buildroot.sh my_team_product_x86_64_main_defconfig || return $?
		expect_xc 0 test ! -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		expect_xc 2 buildroot.sh --output-main all || return $?
		expect_xc 0 test ! -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx mv -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz{.ASIDE,}

		expect_xc 0 buildroot.sh --output-main all || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		expect_xc 0 buildroot.sh --output-main || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		expect_xc 0 buildroot.sh all || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		expect_xc 0 buildroot.sh || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main || return $?
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		cpio -it < buildroot-output-main/images/rootfs.cpio |
		expect_xc 0 egrep '^\.product\.installation\.type$' || return $?

		cpio -it < buildroot-output-main/images/rootfs.cpio |
		expect_xc 0 egrep '^home/debug$' || return $?
		;;

	7|preserve-all-outputs)

		if [ -n "${buildroot_trip_test_debug_p}" ] ; then

			for d1 in buildroot-output-{xctc,main} buildroot-dl-ptb ; do

				xx rsync -a --delete "${d1:?}"{,.~lkg~}/ # lkg == last known good
			done

			for d1 in buildroot-output-rol buildroot-dl-rol ; do

				xx :

				xx sudo rsync -a --delete "${d1:?}"{,.~lkg~}/ # lkg == last known good
			done

			for f1 in buildroot-output-rol.tar ; do

				xx :

				xx sudo rsync -a --delete "${f1:?}"{,.~lkg~} # lkg == last known good
			done
		fi
		;;

	8|main-clean)

		xx :
		xx ln -f buildroot-output-main/images/rootfs.cpio{,.ASIDE}

		expect_xc 0 buildroot.sh --output-main clean || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main || return $?
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx ln -f buildroot-output-main/images/rootfs.cpio{.ASIDE,}

		expect_xc 0 buildroot.sh clean || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main || return $?
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio.ASIDE

		expect_xc 0 test -n "$(xx : && xx find buildroot-dl-ptb -mindepth 2 ! -type d)" || return $?
		expect_xc 0 test -z "$(xx : && xx find buildroot-output-main -mindepth 2 ! -type d)" || return $?
		;;

	9|rol-clean)

		expect_xc 0 buildroot.sh rootfs-overlay --clean-only || return $?
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main || return $?
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar || return $?

		expect_xc 0 test -n "$(xx : && xx find buildroot-dl-rol -mindepth 1 ! -type d)" || return $?
		expect_xc 0 test -z "$(xx : && xx find buildroot-output-rol -mindepth 1 ! -type d)" || return $?
		;;

	10|xctc-clean)

		expect_xc 0 buildroot.sh --output-xctc clean || return $?
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a -d buildroot-output-main || return $?
		expect_xc 0 test ! -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz || return $?

		expect_xc 0 test -n "$(xx : && xx find buildroot-dl-ptb -mindepth 2 ! -type d)" || return $?
		expect_xc 0 test -z "$(xx : && xx find buildroot-output-xctc -mindepth 2 ! -type d)" || return $?
		;;

	11|finish)

		result=done
		;;

	*)
		# skip
		;;
	esac

	assert [ $? -eq 0 ]

	if ! [[ -n ${result} ]] ; then

		state=${state_indexes_by_name_or_index[${state:?}]}

		result=$((++ state))
	fi

	echo "${result}"
}

function buildroot_trip_test_clean() { #

	xx :
	xx sudo rm -rf buildroot-output-rol.tar
	xx sudo rm -rf buildroot-output-rol

	xx :
	xx sudo rm -rf buildroot-dl-rol

	xx :
	xx rm -rf buildroot-output-main

	xx :
	xx rm -rf buildroot-dl-ptb/buildroot-xctc

	xx :
	xx rm -rf buildroot-output-xctc

	xx :
	xx rm -rf buildroot-dl-ptb

	xx :
	xx rm -rf buildroot
	xx rm -rf buildroot*.tar.gz
}

function xx_buildroot_trip_test() { # ...

	buildroot_trip_test "$@"
}

function xx_buildroot_trip_test_run() { # ...

	buildroot_trip_test_run "$@"
}

function xx_buildroot_trip_test_clean() { # ...

	buildroot_trip_test_clean "$@"
}
