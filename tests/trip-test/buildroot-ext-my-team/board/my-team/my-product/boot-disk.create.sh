#!/bin/bash
## Create a boot disk for the target board.
##
## Arguments:
##
##     (none)
##
## Inherited from parent (buildroot post-image) environment:
##
##     BINARIES_DIR, TARGET_DIR
##
## Typical uses:
##
##     boot-disk.create.sh
##

source "$(dirname "$0")"/buildroot-hook.prolog.sh

##
## snippets:
##

function xx() { # ...

	echo 1>&2 "${PS4:-+}" "$@"
	"$@"
}

function get_uuid_from_ext2_fs_image() { # ext2_fs_image_fpn

	local ext2_fs_image_fpn="${1:?}"

	dumpe2fs "${ext2_fs_image_fpn:?}" 2>/dev/null |

	sed -n -e 's/^Filesystem UUID: *\(.*\)/\1/p'
}

function get_first_non_esp_image_name_from_genimage_cfg_file() { # genimage_cfg_fpn

	get_image_names_from_genimage_cfg_file "$@" |

	egrep -v -i '^(efi|esp)' | # omit EFI system partition

	head -1
}

function get_image_names_from_genimage_cfg_file() { # genimage_cfg_fpn

	local genimage_cfg_fpn="${1:?}"

	egrep '^image\b' "${genimage_cfg_fpn:?}" |

	sed -e 's/^image *//' -e 's/{.*//' -e 's/ *$//'
}

function resolve_partition_uuid_in_file() { # template_fpn output_fpn partition_uuid

	local template_fpn="${1:?}" output_fpn="${2:?}" partition_uuid="${3:?}"

	local sed_statement="s/@PARTITION_UUID@/${partition_uuid}/g"

	if [ "${template_fpn:?}" = "${output_fpn:?}" ] ; then

		sed -i -e "${sed_statement:?}" "${output_fpn:?}"
	else
		sed -e "${sed_statement:?}" "${template_fpn:?}" > "${output_fpn:?}"
	fi
}

##
## core logic:
##

this_board_dpn="${this_script_dpn:?}"

grub_cfg_template_fbn="${this_script_fbn%.*.sh}.grub.cfg.in"
grub_cfg_template_fpn="${this_board_dpn:?}/${grub_cfg_template_fbn}"

grub_cfg_fbn="grub.cfg"
grub_cfg_fpn="${BINARIES_DIR:?}/efi-part/EFI/BOOT/${grub_cfg_fbn:?}"

genimage_cfg_template_fbn="${this_script_fbn%.*.sh}.genimage.cfg.in"
genimage_cfg_template_fpn="${this_board_dpn:?}/${genimage_cfg_template_fbn:?}"

genimage_cfg_fbn="${genimage_cfg_template_fbn%.in}"
genimage_cfg_fpn="${BINARIES_DIR:?}/${genimage_cfg_fbn:?}"

genimage_output_fbn="$(
	xx get_first_non_esp_image_name_from_genimage_cfg_file "${genimage_cfg_template_fpn:?}"
)"

genimage_tmp_dbn="${genimage_output_fbn:?}.tmp"
genimage_tmp_dpn="${BINARIES_DIR:?}/${genimage_tmp_dbn:?}"

##

rootfs_ext2_fs_image_fbn="rootfs.ext4"

rootfs_uuid="$(xx get_uuid_from_ext2_fs_image "${BINARIES_DIR:?}/${rootfs_ext2_fs_image_fbn:?}")"

xx resolve_partition_uuid_in_file \
	"${grub_cfg_template_fpn:?}" \
	"${grub_cfg_fpn:?}" \
	"${rootfs_uuid:?}" \
	;

xx resolve_partition_uuid_in_file \
	"${genimage_cfg_template_fpn:?}" \
	"${genimage_cfg_fpn:?}" \
	"${rootfs_uuid:?}" \
	;
##

xx genimage \
	--config "${genimage_cfg_fpn:?}" \
	--tmppath "${genimage_tmp_dpn:?}" \
	--rootpath "${TARGET_DIR:?}" \
	--inputpath "${BINARIES_DIR:?}" \
	--outputpath "${BINARIES_DIR:?}" \
	;

xx rm -rf "${genimage_tmp_dpn:?}"

