#!/bin/bash sourced
## Provides function buildroot_trip_test() and friends.
##

[ -z "$buildroot_trip_test_functions_p" ] || return 0

buildroot_trip_test_functions_p=t

buildroot_trip_test_debug_p=

##

source buildroot_api_config.functions.sh

source buildroot_api_test.functions.sh

source snippet_assert.functions.sh

source snippet_test.functions.sh

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

	load_buildroot_config --defaults file-too --output-none

	##

        if [[ -n ${clean_all_p} ]] ; then

		buildroot_trip_test_clean
	fi

	if [[ ${action:?} != clean ]] ; then

		"buildroot_trip_test_${action:-run}" "${action_args[@]}"
	fi
}

function buildroot_trip_test_run() {( # [ starting_state ]

	local state=${1:-0} ; shift 1 || :

	local final_state_name=finish final_state_index=400 # must be highest

	declare -A state_indexes_by_name_or_index=(

		[0]=0      [start]=0

		[10]=10    [start.scrub]=10

		[20]=20    [start.clean]=20

		[30]=30    [start.install]=30

		[40]=40    [start.config.xctc]=40

		[50]=50    [start.config.main]=50

		[60]=60    [start.build.xctc]=60

		[70]=70    [start.build.rol]=70

		[80]=80    [start.build.main]=80

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

		[${final_state_index:?}]=${final_state_index:?}  [${final_state_name:?}]=${final_state_index:?}
	)

	declare -A state_replacements_by_index

	if [[ -n ${buildroot_trip_test_debug_p} ]] ; then

		state_replacements_by_index+=(

#!#			[${state_indexes_by_name_or_index[start]:?}]=again
		)
	fi

	##

	trap "${FUNCNAME:?}__report_return \$? \${state:?}" EXIT

	if ! [[ -n ${state_indexes_by_name_or_index[${final_state_index:?}]} ]] ; then

		echo 1>&2 "${FUNCNAME:?}: internal error: invalid final-state look-up by index: ${final_state_index:?}"
		return 2
	fi

	if ! [[ -n ${state_indexes_by_name_or_index[${final_state_name:?}]} ]] ; then

		echo 1>&2 "${FUNCNAME:?}: internal error: invalid final-state look-up by key: ${final_state_name:?}"
		return 2
	fi

	while true ; do

		if [[ -n ${buildroot_trip_test_debug_p} ]] ; then

			echo 1>&2 "DEBUG: ${FUNCNAME:?}: state = ${state}"
		fi

		local state_as_index=${state_indexes_by_name_or_index[${state:?}]}

		if ! [[ -n ${state_as_index} ]] ; then

			echo 1>&2 "${FUNCNAME:?}: unrecognized state: ${state:?}"
			return 2
		fi

		! [[ ${state_as_index:?} -eq ${final_state_index:?} ]] || break

		##

		local state_replacement=${state_replacements_by_index[${state_as_index:?}]}

		if [[ -n ${state_replacement} ]] ; then

			state_as_index=${state_indexes_by_name_or_index[${state_replacement:?}]}

			if ! [[ -n ${state_as_index} ]] ; then

				echo 1>&2 "${FUNCNAME:?}: unrecognized state replacement: ${state_replacement:?} (was ${state:?})"
				return 2
			fi

			state=${state_replacement:?}
		fi

		##

		"${FUNCNAME:?}"_1 "${state:?}"

		case $? in (0) ;; (*) return ;; esac

		##

		local next_valid_state_as_index=$((state_as_index + 1))

		while ! [[ -n ${state_indexes_by_name_or_index[${next_valid_state_as_index:?}]} ]] ; do

			((++ next_valid_state_as_index))

			#^-- keep advancing until we hit the next valid state;
			#^-- by design: if nothing else, we will hit the final state
		done

		state=${next_valid_state_as_index:?}
	done
)}

function buildroot_trip_test_run__report_return() { # rc state

	local rc=${1:?missing value for rc} ; shift 1

	local state=${1:?missing value for state} ; shift 1

	if [[ ${rc:?} -eq 0 ]] ; then

		echo 1>&2
		echo 1>&2 "^-- ${this_script_fbn:?}: PASS."
	else
		echo 1>&2
		echo 1>&2 "^-- ${this_script_fbn:?}: FAIL [rc: ${rc:?}; state: ${state:?}]."
	fi
}

function buildroot_trip_test_run_1() {( # [state]

	local state=${1:?missing value for state} ; shift 1

	local d1 f1

	if [[ -n ${buildroot_trip_test_debug_p} ]] ; then

		trap "${FUNCNAME:?}__report_return \$? \${state:?}" EXIT
	fi

	case "${state:?}" in
	10|start.scrub)

		# TODO: implement test phase start.scrub

		;;

	20|start.clean)

		expect_xc 0 buildroot_trip_test_clean
		expect_xc 0 test_buildroot_condition dl-ptb:\? xctc:no xctc-sdk:image:no,pa:no,dl:no rol:no main:no
		expect_xc 0 test ! -n "$(ls -d buildroot*.tar.gz 2>&- | head -1)"
		expect_xc 0 test ! -d buildroot

		;;

	30|start.install)

		xx :
		expect_xc 2 xx buildroot install --bad-option
		expect_xc 0 test ! -d buildroot

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		xx :
		expect_xc 0 xx buildroot install --everything
		expect_xc 0 test -d buildroot -a -n "$(sudo_pass_through which debootstrap)"

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		xx :
		expect_xc 0 xx buildroot install --dependencies-only
		expect_xc 0 test ! -d buildroot -a -n "$(sudo_pass_through which debootstrap)"

		xx :
		xx rm -rf buildroot*.tar.gz
		xx rm -rf buildroot

		xx :
		expect_xc 0 xx buildroot install
		expect_xc 0 test -d buildroot -a -n "$(sudo_pass_through which debootstrap)"

		;;

	40|start.config.xctc)

		# TODO: implement these tests

		;;

	50|start.config.main)

		# TODO: implement these tests

		;;

	60|start.build.xctc)

		xx :
		expect_xc 2 xx buildroot --output-main toolchain
		expect_xc 0 test_buildroot_condition dl-ptb:no xctc:no xctc-sdk:image:no,pa:no,dl:no rol:no main:no

		xx :
		expect_xc 2 xx buildroot --output-main sdk
		expect_xc 0 test_buildroot_condition dl-ptb:no xctc:no xctc-sdk:image:no,pa:no,dl:no rol:no main:no

		xx :
		expect_xc 2 xx buildroot --output-xctc my_team_product_x86_64_main_defconfig
		expect_xc 0 test_buildroot_condition dl-ptb:no xctc:no xctc-sdk:image:no,pa:no,dl:no rol:no main:no

		xx :
		expect_xc 0 xx buildroot --output-xctc my_team_product_x86_64_xctc_defconfig
		expect_xc 0 test_buildroot_condition dl-ptb:no xctc:YES xctc-sdk:image:no,pa:no,dl:no rol:no main:no

		remove_buildroot_xctc_sdk_tarball --image --pa

		xx :
		expect_xc 0 xx buildroot --output-xctc toolchain
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:YES,pa:YES,dl:no rol:no main:no

		remove_buildroot_xctc_sdk_tarball --image --pa

		xx :
		expect_xc 0 xx buildroot --output-xctc sdk
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:YES,pa:YES,dl:no rol:no main:no

		remove_buildroot_xctc_sdk_tarball --image --pa

		xx :
		expect_xc 0 xx buildroot --output-xctc
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:YES,pa:YES,dl:no rol:no main:no

		remove_buildroot_xctc_sdk_tarball --image --pa

		xx :
		expect_xc 0 xx buildroot --output-xctc all
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:YES,pa:YES,dl:no rol:no main:no

		remove_buildroot_xctc_sdk_tarball --image --pa

		xx :
		expect_xc 0 xx buildroot toolchain
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:YES,pa:YES,dl:no rol:no main:no

		remove_buildroot_xctc_sdk_tarball --image --pa

		xx :
		expect_xc 0 xx buildroot sdk
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:YES,pa:YES,dl:no rol:no main:no

		;;

	70|start.build.rol)

		xx :
		expect_xc 2 xx buildroot rootfs-overlay --bad-option
		expect_xc 0 test_buildroot_condition dl-rol:no rol:no,debootstrap:no,tarball:no main:no

		xx :
		expect_xc 1 xx buildroot rootfs-overlay --build --clean-only
		expect_xc 0 test_buildroot_condition dl-rol:no rol:no,debootstrap:no,tarball:no main:no

		xx :
		expect_xc 1 xx buildroot rootfs-overlay --build --clean-first --clean-only
		expect_xc 0 test_buildroot_condition dl-rol:no rol:no,debootstrap:no,tarball:no main:no

		xx :
		expect_xc 1 xx buildroot rootfs-overlay --clean-first --clean-only
		expect_xc 0 test_buildroot_condition dl-rol:no rol:no,debootstrap:no,tarball:no main:no

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --download-only
		expect_xc 0 test_buildroot_condition dl-rol:no rol:no,debootstrap:no,tarball:no main:no

		xx :
		expect_xc 0 xx buildroot my_team_product_x86_64_main_defconfig
		expect_xc 0 test_buildroot_condition dl-rol:no rol:no,debootstrap:no,tarball:no main:YES

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --download-only
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:no main:YES

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --build --download-only
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:no main:YES

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --build --clean-first
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:YES main:YES

		xx :
		xx sudo_pass_through rm -rf buildroot-output-rol

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --build
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:YES main:YES

		xx :
		xx sudo_pass_through rm -rf buildroot-output-rol.tar

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --build
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:YES main:YES

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --clean-first
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:YES main:YES

		xx :
		expect_xc 0 xx buildroot rootfs-overlay
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:YES main:YES

		;;

	80|start.build.main)

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		xx :
		xx rm -rf buildroot-dl-ptb/toolchain-external-custom

		xx :
		expect_xc 0 xx buildroot toolchain{,-external{,-custom}}-dirclean

		xx :
		xx mv -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz{,.ASIDE}

		xx :
		expect_xc 0 xx buildroot my_team_product_x86_64_main_defconfig
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:NO,dl:no rol:tarball:YES main:YES,rootfs:no

		xx :
		expect_xc 2 xx buildroot --output-main all
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:NO,dl:no rol:tarball:YES main:YES,rootfs:no

		xx :
		xx mv -f buildroot-dl-ptb/buildroot-xctc/x86_64-buildroot-linux-gnu_sdk-buildroot.tar.gz{.ASIDE,}

		xx :
		expect_xc 0 xx buildroot --output-main all
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:YES,dl:YES rol:tarball:YES main:YES,rootfs:YES

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		xx :
		expect_xc 0 xx buildroot --output-main
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:YES,dl:YES rol:tarball:YES main:YES,rootfs:YES

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		xx :
		expect_xc 0 xx buildroot all
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:YES,dl:YES rol:tarball:YES main:YES,rootfs:YES

		xx :
		xx rm -f buildroot-output-main/images/rootfs.cpio

		xx :
		expect_xc 0 xx buildroot
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:YES,dl:YES rol:tarball:YES main:YES,rootfs:YES

		expect_xc 0 test -n "$(
			xx : && xx : count: && 
			xx cat buildroot-output-main/images/rootfs.cpio |
			xx cpio -it | xx egrep '^home/debug$'
		)"

		expect_xc 0 test -n "$(
			xx : && xx : count: && 
			xx cat buildroot-output-main/images/rootfs.cpio |
			xx cpio -it | xx egrep '^[.]product[.]installation[.]type$'
		)"

		;;

	210|stash.all-outputs)

		if [[ -n ${buildroot_trip_test_debug_p} ]] ; then

			for d1 in buildroot-output-{xctc,main} buildroot-dl-ptb ; do

				xx rsync -a --delete "${d1:?}"{,.~lkg~}/ # lkg == last known good
			done

			for d1 in buildroot-output-rol buildroot-dl-rol ; do

				xx :

				xx sudo_pass_through rsync -a --delete "${d1:?}"{,.~lkg~}/ # lkg == last known good
			done

			for f1 in buildroot-output-rol.tar ; do

				xx :

				xx sudo_pass_through rsync -a --delete "${f1:?}"{,.~lkg~} # lkg == last known good
			done
		fi

		;;

	310|clean.main)

		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:YES,dl:YES rol:tarball:YES main:YES,rootfs:YES

		xx :
		expect_xc 0 xx buildroot --output-main clean
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc-sdk:pa:YES,dl:YES rol:tarball:YES main:YES,rootfs:NO

		expect_xc 0 test -n "$(xx : && xx : count: && xx find buildroot-dl-ptb -mindepth 2 ! -type d)"
		expect_xc 0 test -z "$(xx : && xx : count: && xx find buildroot-output-main -mindepth 2 ! -type d)"

		;;

	320|clean.rol)

		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:YES,tarball:YES main:YES

		xx :
		expect_xc 0 xx buildroot rootfs-overlay --clean-only
		expect_xc 0 test_buildroot_condition dl-rol:YES rol:YES,debootstrap:NO,tarball:NO main:YES

		expect_xc 0 test -n "$(xx : && xx : count: && xx find buildroot-dl-rol -mindepth 1 ! -type d)"
		expect_xc 0 test -z "$(xx : && xx : count: && xx find buildroot-output-rol -mindepth 1 ! -type d)"

		;;

	330|clean.xctc)

		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:pa:YES,dl:YES main:YES

		xx :
		expect_xc 0 xx buildroot --output-xctc clean
		expect_xc 0 test_buildroot_condition dl-ptb:YES xctc:YES xctc-sdk:image:NO,pa:YES,dl:YES main:YES

		expect_xc 0 test -n "$(xx : && xx : count: && xx find buildroot-dl-ptb -mindepth 2 ! -type d)"
		expect_xc 0 test -z "$(xx : && xx : count: && xx find buildroot-output-xctc -mindepth 2 ! -type d)"

		;;

	${final_state_index:?}|${final_state_name:?})

		# all done

		;;

	*)
		# skip

		;;
	esac
)}

function buildroot_trip_test_run_1__report_return() { # rc state

	local rc=${1:?missing value for rc} ; shift 1

	local state=${1:?missing value for state} ; shift 1

	echo 1>&2 "DEBUG: ${FUNCNAME%__report_return}: returning; rc: ${rc:?}; state: ${state}"
}

function buildroot_trip_test_clean() { #

	xx :
	xx sudo_pass_through rm -rf buildroot-output-rol.tar
	xx sudo_pass_through rm -rf buildroot-output-rol

	xx :
	xx sudo_pass_through rm -rf buildroot-dl-rol

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

