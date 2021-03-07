#!/bin/bash
## A wrapper around make(1) and helper scripts for a buildroot-based build.
##
## Arguments:
##
##     [ --output-main ] [ make ] [ clean | all | linux-menuconfig | <any-non-xctc-buildroot-make-arg> ... ]
## 
##     [ --output-xctc ] [ make ] [ clean | all | toolchain | sdk | <any-non-linux-buildroot-make-arg> ... ]
## 
##     [ --output-rol  ] [ make ] [ clean | all ]
## 
##     [ [ --output-main ] | --output-xctc ] host-tree [ <any-buildroot-host-tree-arg> ... ]
## 
##     [ [ --output-main ] | --output-xctc ] target-tree [ <any-buildroot-target-tree-arg> ... ]
## 
##     all-output-trees [ <any-buildroot-all-output-trees-arg> ... ]
##     
##     eval [ <any-bash-eval-arg> ... ]
##     
##     install [ <any-buildroot-install-arg> ... ]
## 
##     qemu-vm [ <any-buildroot-qemu-vm-arg> ... ]
## 
##     trip-test [ <any-buildroot-trip-test-arg> ... ]
## 
##     rootfs-overlay [ <any-buildroot-rootfs-overlay-arg> ... ]
## 
##     api [ module ]
## 
## Typical uses:
## 
##     buildroot.sh
##     buildroot.sh all
##     buildroot.sh --output-main all
##     buildroot.sh --output-xctc all
##     buildroot.sh --output-rol  all
##     
##     buildroot.sh clean
##     buildroot.sh --output-main clean
##     buildroot.sh --output-xctc clean
##     buildroot.sh --output-rol  clean
##     
##     buildroot.sh toolchain sdk
##     buildroot.sh --output-xctc toolchain sdk
##     
##     buildroot.sh my_target_board_main_defconfig
##     buildroot.sh --output-main my_target_board_main_defconfig
##     
##     buildroot.sh my_target_board_xctc_defconfig
##     buildroot.sh --output-xctc my_target_board_xctc_defconfig
##     
##     buildroot.sh update-defconfig
##     buildroot.sh --output-main update-defconfig
##     buildroot.sh --output-xctc update-defconfig
##     
##     buildroot.sh linux-menuconfig
##     buildroot.sh --output-main linux-menuconfig
##     
##     buildroot.sh linux-update-defconfig
##     buildroot.sh --output-main linux-update-defconfig
##     
##     buildroot.sh make ...
##     buildroot.sh --output-main make ...
##     buildroot.sh --output-xctc make ...
##     
##     buildroot.sh host-tree
##     buildroot.sh host-tree --build
##     buildroot.sh host-tree --clean-only
##     buildroot.sh host-tree --clean-first
##     buildroot.sh --output-main host-tree ...
##     buildroot.sh --output-xctc host-tree ...
##    
##     buildroot.sh target-tree
##     buildroot.sh target-tree --build
##     buildroot.sh target-tree --clean-only
##     buildroot.sh target-tree --clean-first
##     buildroot.sh --output-main target-tree ...
##     buildroot.sh --output-xctc target-tree ...
##    
##     buildroot.sh rootfs-overlay
##     buildroot.sh rootfs-overlay --build
##     buildroot.sh rootfs-overlay --clean-only
##     buildroot.sh rootfs-overlay --clean-first
##     buildroot.sh rootfs-overlay --clean-tarball-only
##     buildroot.sh rootfs-overlay --clean-tarball-first
##     buildroot.sh rootfs-overlay --download-only
##     
##     buildroot.all-output-trees.sh
##     buildroot.all-output-trees.sh --build
##     buildroot.all-output-trees.sh --build :infer:main
##     buildroot.all-output-trees.sh --build my_team_product_main_defconfig
##     buildroot.all-output-trees.sh --build my_team_product_main_defconfig :infer:xctc
##     buildroot.all-output-trees.sh --build my_team_product_main_defconfig my_team_product_xctc_defconfig
##     buildroot.all-output-trees.sh --build my_team_product_main_defconfig :skip:xctc
##     
##     buildroot.all-output-trees.sh --clean-first :infer:main
##     buildroot.all-output-trees.sh --clean-first my_team_product_main_defconfig
##     buildroot.all-output-trees.sh --clean-first my_team_product_main_defconfig :infer:xctc
##     buildroot.all-output-trees.sh --clean-first my_team_product_main_defconfig my_team_product_xctc_defconfig
##     buildroot.all-output-trees.sh --clean-first my_team_product_main_defconfig :skip:xctc
##     
##     buildroot.all-output-trees.sh --clean-only
##     buildroot.all-output-trees.sh --clean-only :infer:main
##     buildroot.all-output-trees.sh --clean-only my_team_product_main_defconfig
##     buildroot.all-output-trees.sh --clean-only my_team_product_main_defconfig :infer:xctc
##     buildroot.all-output-trees.sh --clean-only my_team_product_main_defconfig my_team_product_xctc_defconfig
##     buildroot.all-output-trees.sh --clean-only my_team_product_main_defconfig :skip:xctc
##
##     buildroot.sh qemu-vm --run
##     buildroot.sh qemu-vm --run --using-initrd
##     buildroot.sh qemu-vm --run --using-boot-disk
##
##     buildroot.sh trip-test --run
##     buildroot.sh trip-test --clean-only
##     buildroot.sh trip-test --clean-first
##     
##     ! command -v buildroot || source "$(buildroot api)"
##     ! command -v buildroot || source "$(buildroot api '')"
##     ! command -v buildroot || source "$(buildroot api config)"
##     ! command -v buildroot || for f1 in $(buildroot api config cwd) ; do source "$f1" ; done
##     
## See also:
##
##     ../bin/thunk/buildroot.all-output-trees.sh
##     ../bin/thunk/buildroot.host-tree.sh
##     ../bin/thunk/buildroot.install.sh
##     ../bin/thunk/buildroot.make.sh
##     ../bin/thunk/buildroot.qemu-vm.sh
##     ../bin/thunk/buildroot.rootfs-overlay.sh
##     ../bin/thunk/buildroot.target-tree.sh
##     ../bin/thunk/buildroot.trip-test.sh
## 

source "$(dirname "${BASH_SOURCE:?}")"/../libexec/buildroot_cli.prolog.sh

source buildroot_cli_dispatcher.functions.sh

##

function main() { # ...

	buildroot_cli_dispatcher "$@"
}

! [ "$0" = "${BASH_SOURCE}" ] || main "$@"
