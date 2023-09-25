#!/bin/bash
set -e

# Source configurations and other necessary scripts
source "$(dirname "$(readlink -f "$0")")/00-config.sh"
source "${SCRIPTS_DIR}/00-arm64-cross-compile.sh"

# Go back to starting dir on script exit
STARTING_DIR="$PWD"
function cleanup {
	cd "$STARTING_DIR"
}
trap cleanup EXIT

# Clean up old directories
rm -rf "${ROOTFS_BASE_DIR}"

info "Bootstrapping Kali with $DEBOOTSTRAP"
mkdir -p "${CACHE_DIR}"

# Creating initial Kali system using debootstrap
mkdir -p "${ROOTFS_BASE_DIR}"
chown root:root "${ROOTFS_BASE_DIR}"
eatmydata $DEBOOTSTRAP \
		--arch=arm64 \
		--cache-dir="${CACHE_DIR}" \
		--include=apt,initramfs-tools,eatmydata \
		"${KALI_CODE}" \
		"${ROOTFS_BASE_DIR}" \
		http://http.kali.org/kali 2>&1| capture_and_log "bootstrap kali"

# Syncing data after bootstrap
info "Syncing data to filesystem"
sync

info "Syncing common files to rootfs"
rsync -arHAX --chown root:root "${FS_COMMON_DIR}/" "${ROOTFS_BASE_DIR}/" 2>&1| capture_and_log "rsync common files"

# Create ESP dir, to be mounted later
mkdir -p "${ROOTFS_BASE_DIR}/boot/efi"

perl -p -i -e 's/root:x:/root::/' "${ROOTFS_BASE_DIR}/etc/passwd"

info "Linking systemd to init"
ln -s lib/systemd/systemd "${ROOTFS_BASE_DIR}/init"
