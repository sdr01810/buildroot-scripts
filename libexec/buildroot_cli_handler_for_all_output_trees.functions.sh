#!/bin/bash sourced
## Manage all output trees generated by a buildroot-based build.
## 
## Arguments:
##
##     --clean-only 
##     
##     [ --build ] [ --clean-first ] main_defconfig_fbn [ xctc_defconfig_fbn ]
## 
## Typical uses:
##
##     buildroot_all_output_trees my_team_product_main_defconfig
##     buildroot_all_output_trees my_team_product_main_defconfig my_team_product_xctc_defconfig
##     
##     buildroot_all_output_trees --build my_team_product_main_defconfig
##     buildroot_all_output_trees --build my_team_product_main_defconfig  my_team_product_xctc_defconfig
##     
##     buildroot_all_output_trees --clean-first my_team_product_main_defconfig
##     buildroot_all_output_trees --clean-first my_team_product_main_defconfig my_team_product_xctc_defconfig
##     
##     buildroot_all_output_trees --clean-only
## 

[ -z "$buildroot_cli_handler_for_all_output_trees_functions_p" ] || return 0

buildroot_cli_handler_for_all_output_trees_functions_p=t

buildroot_cli_handler_for_all_output_trees_debug_p=

##

source buildroot_api_all_output_trees.functions.sh

##

function buildroot_cli_handler_for_all_output_trees() { # ...

	buildroot_all_output_trees "$@"
}

