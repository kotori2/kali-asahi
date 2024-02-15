#!/bin/bash
set -e

export LC=C.UTF-8

SOURCE_DATE_EPOCH="$(git --git-dir="$PWD/../.git" log -1 --format='%ct' 2> /dev/null || echo "42")"
DISTRO_NAME=kali
DISTRO_VERSION=$(grep VERSION /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
DISTRO_VOLUME_LABEL="Kali Linux ${DISTRO_VERSION} arm64"
DISTRO_EPOCH="${SOURCE_DATE_EPOCH}"
DISTRO_DATE="$(date --date=@"${SOURCE_DATE_EPOCH}" +%Y%m%d)"

DISTRO_PKGS=(kali-linux-core)  # Modify this according to your needs for base Kali packages
LIVE_PKGS=(kali-linux)  # Modify this according to your needs for live Kali packages
DISK_PKGS=(grub-efi kali-linux-full)  # Modify this according to your needs for disk Kali packages
HOLD_PKGS=()
RM_PKGS=()
MAIN_POOL=()

EFI_UUID=2ABF-9F91
ROOT_UUID=87c6b0ce-3bb6-4dc2-9298-3a799bbb5994

SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_DIR="$(realpath "${SCRIPTS_DIR}/../build")"
CACHE_DIR="${BUILD_DIR}/cache"
TMP_DIR="/tmp/kali-asahi.build/"
SQUASHFS_FILE="${BUILD_DIR}/rootfs.squashfs"

FS_DIR="$(realpath "${SCRIPTS_DIR}/../fs")"
FS_COMMON_DIR="${FS_DIR}/common"
FS_DISK_DIR="${FS_DIR}/disk"
FS_LIVE_DIR="${FS_DIR}/live"
FS_LIVE_EFI_DIR="${FS_DIR}/live-efi"
FS_DISK_EFI_DIR="${FS_DIR}/disk-efi"
FS_DEBS_DIR="${FS_DIR}/debs"
FS_POOL_DIR="${FS_DIR}/pool"

ROOTFS_BASE_DIR="${BUILD_DIR}/rootfs.base"
ROOTFS_DISK_DIR="${BUILD_DIR}/rootfs.disk"
ROOTFS_LIVE_DIR="${BUILD_DIR}/rootfs.live"

CHROOT_MANIFEST="${BUILD_DIR}/chroot.manifest"
LIVE_MANIFEST="${BUILD_DIR}/live.manifest"

DISK_IMG_FILE="${BUILD_DIR}/kali.disk.img"
LIVE_IMG_FILE="${BUILD_DIR}/kali.live.img"

CASPER_NAME="casper"
MNT_DIR="${BUILD_DIR}/mnt"
DOT_DISK_INFO="${MNT_DIR}/.disk/info"
CASPER_DIR="${MNT_DIR}/${CASPER_NAME}"
FILESYSTEM_SIZE_TAG="${CASPER_DIR}/filesystem.size"
ROOTFS_SQUASHED="${CASPER_DIR}/filesystem.squashfs"
POOL_DIR="${MNT_DIR}/pool"
MAIN_POOL_DIR="${POOL_DIR}/main"
DISTS_DIR="${MNT_DIR}/dists"

SED_PATTERN="s|CASPER_PATH|${CASPER_NAME}|g; s|DISTRO_NAME|${DISTRO_NAME}|g; s|DISTRO_VERSION|${DISTRO_VERSION}|g; s|DISTRO_EPOCH|${DISTRO_EPOCH}|g; s|DISTRO_DATE|${DISTRO_DATE}|g"

_RED=$(tput setaf 1 || "")
_GREEN=$(tput setaf 2 || "")
_YELLOW=$(tput setaf 3 || "")
_RESET=$(tput sgr0 || "")
_BOLD=$(tput bold || "")
_DIM=$(tput dim || "")

function bold {
	echo "${_BOLD}$@${_RESET}"
}

function info {
	echo "[${_GREEN}${_BOLD}info${_RESET}] $@"
}

function error {
	echo "[${_RED}${_BOLD}error${_RESET}] $@"
}

function warn {
	echo "[${_YELLOW}${_BOLD}warning${_RESET}] $@"
}

function capture_and_log {
	PREFIX="[${_GREEN}${_BOLD}$1${_RESET}] ${_DIM}"
	SUFFIX="${_RESET}"
	while read IN
	do
		echo "${PREFIX}${IN}${SUFFIX}"
	done
}

# if [[ "${EUID:-$(id -u)}" != 0 ]]; then
# 	error "This script must be run as root."
# 	exit 1
# fi

# Source: https://stackoverflow.com/a/17841619
function join_by { local IFS="$1"; shift; echo "$*"; }

if [[ "$(uname -p)" -ne "aarch64" ]]; then
	update-binfmts --enable
fi
