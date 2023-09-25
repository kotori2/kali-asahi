#!/bin/bash
set -e

source /00-config.sh
rm -f /00-config.sh

info "Fixing DNS"
ln -fs /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Update the package database
info "Updating package database"
eatmydata apt-get --yes update 2>&1| capture_and_log "apt update"

# Install local debs if available
NUM_DEBS_TO_INSTALL=$(find /debs -name "*.deb" -type f | wc -l)
if [ ${NUM_DEBS_TO_INSTALL} -gt 0 ]; then
    info "Installing ${NUM_DEBS_TO_INSTALL} extra debs"
    eatmydata apt-get --yes install /debs/*.deb 2>&1| capture_and_log "install custom debs"
fi
rm -rf /debs

# Remove unnecessary packages
if [ ${#RM_PKGS[@]} -ne 0 ]; then
    apt-get purge ${RM_PKGS[@]} 2>&1| capture_and_log "remove packages"
fi

# Mark certain packages to hold
if [ ${#HOLD_PKGS[@]} -ne 0 ]; then
    apt-mark hold ${HOLD_PKGS[@]} 2>&1| capture_and_log "hold packages"
fi

# Install primary distro packages, adjust for Kali
if [ ${#DISTRO_PKGS[@]} -ne 0 ]; then
    eatmydata apt-get --yes install ${DISTRO_PKGS[@]} 2>&1| capture_and_log "install kali-linux-large"
fi

# Upgrade all packages.
eatmydata apt-get --yes dist-upgrade --allow-downgrades 2>&1| capture_and_log "apt upgrade"

info "Cleaning up old boot files"
rm -rf /boot/efi/EFI/Kali  # Adjusted to Kali

# Clean up any unused dependencies
eatmydata apt-get --yes autoremove --purge 2>&1| capture_and_log "apt autoremove"

info "Unmounting apt cache"
umount /var/cache/apt/archives

# Clean up the apt caches
eatmydata apt-get --yes autoclean 2>&1| capture_and_log "apt autoclean"
eatmydata apt-get --yes clean 2>&1| capture_and_log "apt clean"

info "Synchronizing changes to disk"
sync

info "Creating missing NetworkManager config"
mkdir -p /etc/NetworkManager/conf.d/
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

info "Creating base filesystem manifest"
dpkg-query -W --showformat='${Package}\t${Version}\n' > /manifest

info "Cleaning up data..."
rm -rf /tmp/*
rm -f /var/lib/dbus/machine-id

# Additional steps and adjustments might be necessary depending on the specific requirements.
