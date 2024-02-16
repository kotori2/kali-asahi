#!/bin/bash
set -e

source /00-config.sh
rm -f /00-config.sh

export DEBIAN_FRONTEND=noninteractive

apt-get --yes update 2>&1| capture_and_log "apt update"

if [ ${#LIVE_PKGS[@]} -ne 0 ]; then
    eatmydata apt-get --yes install ${DISK_PKGS[@]} 2>&1| capture_and_log "install disk packages"
fi

info "Synchronizing changes to disk"
sync

info "Installing grub"
cat > /tmp/grub-core.cfg <<EOF
search.fs_uuid ${ROOT_UUID} root
set prefix=(\$root)'/boot/grub'
EOF

mkdir -p /boot/grub
touch /boot/grub/device.map
cp -r /usr/lib/grub/arm64-efi /boot/grub/
rm -f /boot/grub/arm64-efi/*.module
mkdir -p /boot/grub/{fonts,locale}
cp /usr/share/grub/unicode.pf2 /boot/grub/fonts
echo "GRUB_DISABLE_OS_PROBER=true" >> "/etc/default/grub"

info "Generating grub image"
grub-mkimage \
    --directory '/usr/lib/grub/arm64-efi' \
    -c /tmp/grub-core.cfg \
    --prefix "/boot/grub" \
    --output /boot/grub/arm64-efi/core.efi \
    --format arm64-efi \
    --compression auto \
    ext2 part_gpt search
rm -rf /etc/grub.d/30_uefi-firmware

info "Adding user kali"
useradd kali -s /bin/bash -m -G sudo,adm,dialout,cdrom,dip,plugdev,lpadmin
chpasswd << 'END'
kali:kali
END
usermod -L root

info "Cleaning up data..."
rm -rf /tmp/*
rm -f /var/lib/dbus/machine-id
