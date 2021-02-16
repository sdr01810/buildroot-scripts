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

	while [[ ${#} -gt 0 ]] ; do
        case "${1}" in
	--run)
		action=${action:-run}
		[[ ${action:?} == run ]]

		shift 1
		;;
	--clean-only)
		action=${action:-clean}
		[[ ${action:?} == clean ]]

		clean_all_p=t

		shift 1
		;;
	--clean-first)
		action=${action:-run}
		[[ ${action:?} == run ]]

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

	action_args+=( "${@}" ) ; shift ${#}

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

	while [[ -n ${current_state} && ${current_state:?} != done ]] ; do

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

	local state=${1:?missing value for state} ; shift 1

	declare -A state_indexes_by_name_or_index=(

		[0]=0      [start]=0

		[10]=10    [start.clean]=10

		[20]=20    [start.install]=20

		[30]=30    [start.config.xctc]=30

		[40]=40    [start.config.main]=40

		[50]=50    [start.build.xctc]=50

		[60]=60    [start.build.rol]=60

		[70]=70    [start.build.main]=70

		##

		[100]=100  [again]=100

		[110]=110  [again.install]=110

		[120]=120  [again.config.xctc]=120

		[130]=130  [again.config.main]=130

		[140]=140  [again.build.xctc]=140

		[150]=150  [again.build.rol]=150

		[160]=160  [again.build.main]=160

		##

		[200]=200  [stash]=200

		[210]=210  [stash.all-outputs]=210

		##

		[300]=300  [clean]=300

		[310]=310  [clean.main]=310

		[320]=320  [clean.rol]=320

		[330]=330  [clean.xctc]=330

		##

		[999]=999  [finish]=999
	)

	declare -A state_replacements_by_index

	! [[ -n ${buildroot_trip_test_debug_p} ]] ||
	state_replacements_by_index+=(

#!#		[${state_indexes_by_name_or_index[start]:?}]=again
	)

	local d1 f1

	local result=

	state=${state_indexes_by_name_or_index[${state:?}]}

	if [[ -n ${state_replacements_by_index[${state:?}]} ]] ; then

		state=${state_replacements_by_index[${state:?}]}
	fi

	case "${state:?}" in
	10|start.clean)

		expect_xc 0 buildroot_trip_test_clean
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -n "$(ls -d buildroot*.tar.gz 2>&- | head -1)"
		expect_xc 0 test ! -d buildroot-output-xctc
		expect_xc 0 test ! -d buildroot-output-main
		expect_xc 0 test ! -d buildroot
		;;

	20|start.install)

		expect_xc 2 buildroot.sh >&- install --bad-option
		expect_xc 0 test ! -d buildroot

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		expect_xc 0 buildroot.sh >&- install --everything
		expect_xc 0 test -d buildroot -a -n "$(sudo which debootstrap)"

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		expect_xc 0 buildroot.sh >&- install --dependencies-only
		expect_xc 0 test ! -d buildroot -a -n "$(sudo which debootstrap)"

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		expect_xc 0 buildroot.sh >&- install
		expect_xc 0 test -d buildroot -a -n "$(sudo which debootstrap)"
		;;

	30|start.config.xctc)

		# TODO: implement these tests
		;;

	40|start.config.main)

		# TODO: implement these tests
		;;

	50|start.build.xctc)

		expect_xc 1 buildroot.sh >&- --output-main toolchain
		expect_xc 0 test ! -d buildroot-dl-ptb -a ! -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 1 buildroot.sh >&- --output-main sdk
		expect_xc 0 test ! -d buildroot-dl-ptb -a ! -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 1 buildroot.sh >&- --output-xctc my_team_product_x86_64_main_defconfig
		expect_xc 0 test ! -d buildroot-dl-ptb -a ! -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- --output-xctc my_team_product_x86_64_xctc_defconfig
		expect_xc 0 test ! -d buildroot-dl-ptb -a   -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test ! -e buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -e buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- --output-xctc toolchain
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- --output-xctc sdk
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- --output-xctc
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- --output-xctc all
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- toolchain
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		xx :
		xx rm -f buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		xx rm -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 buildroot.sh >&- sdk
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a ! -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		;;

	60|start.build.rol)

		expect_xc 2 buildroot.sh >&- rootfs-overlay --bad-option
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 1 buildroot.sh >&- rootfs-overlay --build --clean-only
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 1 buildroot.sh >&- rootfs-overlay --build --clean-first --clean-only
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 1 buildroot.sh >&- rootfs-overlay --clean-first --clean-only
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay --download-only
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a ! -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- my_team_product_x86_64_main_defconfig
		expect_xc 0 test ! -d buildroot-dl-rol -a ! -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay --download-only
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay --build --download-only
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay --build --clean-first
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar

		xx :
		xx sudo rm -rf buildroot-output-rol

		expect_xc 0 buildroot.sh >&- rootfs-overlay --build
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar

		xx :
		xx sudo rm -rf buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay --build
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay --clean-first
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar

		expect_xc 0 buildroot.sh >&- rootfs-overlay
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test -d buildroot-output-rol/debootstrap -a -s buildroot-output-rol.tar
		;;

	70|start.build.main)

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -rf buildroot-dl-ptb/toolchain-external-custom

		expect_xc 0 buildroot.sh >&- toolchain{,-external{,-custom}}-dirclean

		xx :
		xx mv -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz{,.ASIDE}

		expect_xc 0 buildroot.sh >&- my_team_product_x86_64_main_defconfig
		expect_xc 0 test ! -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		expect_xc 2 buildroot.sh >&- --output-main all
		expect_xc 0 test ! -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx mv -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz{.ASIDE,}

		expect_xc 0 buildroot.sh >&- --output-main all
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		expect_xc 0 buildroot.sh >&- --output-main
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		expect_xc 0 buildroot.sh >&- all
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		expect_xc 0 buildroot.sh >&-
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main
		expect_xc 0 test -s buildroot-output-main/images/rootfs.cpio

		cpio -it < buildroot-output-main/images/rootfs.cpio |
		expect_xc 0 egrep '^\.product\.installation\.type$'

		cpio -it < buildroot-output-main/images/rootfs.cpio |
		expect_xc 0 egrep '^home/debug$'
		;;

	210|stash.all-outputs)

		if [[ -n ${buildroot_trip_test_debug_p} ]] ; then

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

	310|clean.main)

		xx :
		xx ln -f buildroot-output-main/images/rootfs.cpio{,.ASIDE}

		expect_xc 0 buildroot.sh >&- --output-main clean
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx ln -f buildroot-output-main/images/rootfs.cpio{.ASIDE,}

		expect_xc 0 buildroot.sh >&- clean
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-main
		expect_xc 0 test ! -s buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio.ASIDE

		expect_xc 0 test -n "$(xx : && xx find buildroot-dl-ptb -mindepth 2 ! -type d)"
		expect_xc 0 test -z "$(xx : && xx find buildroot-output-main -mindepth 2 ! -type d)"
		;;

	320|clean.rol)

		expect_xc 0 buildroot.sh >&- rootfs-overlay --clean-only
		expect_xc 0 test -d buildroot-dl-rol -a -d buildroot-output-rol -a -d buildroot-output-main
		expect_xc 0 test ! -d buildroot-output-rol/debootstrap -a ! -s buildroot-output-rol.tar

		expect_xc 0 test -n "$(xx : && xx find buildroot-dl-rol -mindepth 1 ! -type d)"
		expect_xc 0 test -z "$(xx : && xx find buildroot-output-rol -mindepth 1 ! -type d)"
		;;

	330|clean.xctc)

		expect_xc 0 buildroot.sh >&- --output-xctc clean
		expect_xc 0 test -d buildroot-dl-ptb -a -d buildroot-output-xctc -a -d buildroot-output-main
		expect_xc 0 test ! -s buildroot-output-xctc/images/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz
		expect_xc 0 test -s buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz

		expect_xc 0 test -n "$(xx : && xx find buildroot-dl-ptb -mindepth 2 ! -type d)"
		expect_xc 0 test -z "$(xx : && xx find buildroot-output-xctc -mindepth 2 ! -type d)"
		;;

	999|finish) # must be highest state

		result=done
		;;

	*)
		# skip
		;;
	esac

	assert [ $? -eq 0 ]

	if ! [[ -n ${result} ]] ; then

		state=${state_indexes_by_name_or_index[${state:?}]}
		#^-- ensure current state is in index form

		while true ; do

			((++ state))

			! [[ -n ${state_indexes_by_name_or_index[${state:?}]} ]] || break

			#^-- keep advancing until we hit the next valid state; 
			#^-- by design: eventually we will hit state 'finish'
		done

		result=${state:?}
	fi

	echo "${result:?}"
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

	buildroot_trip_test "${@}"
}

function xx_buildroot_trip_test_run() { # ...

	buildroot_trip_test_run "${@}"
}

function xx_buildroot_trip_test_clean() { # ...

	buildroot_trip_test_clean "${@}"
}
