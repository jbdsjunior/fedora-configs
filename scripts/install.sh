#!/bin/bash
# Script para aplicar configurações customizadas no Fedora Plasma

# 1. Sysctl Otimizações
sudo cp ../rootfs/sysctl/*.conf /etc/sysctl.d/99-custom-settings.conf
sudo sysctl --system

# 2. DNS Over TLS
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo cp ../rootfs/dns/dns-override.conf /etc/systemd/resolved.conf.d/custom-dns.conf
sudo systemctl restart systemd-resolved

# 3. Virtualização e BTRFS (No_COW)
sudo cp ../rootfs/tmpfiles/kvm.conf /etc/tmpfiles.d/custom-kvm.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/custom-kvm.conf

# 4. NetworkManager (MAC Randomization e Privacy)
sudo cp ../rootfs/nm/*.conf /etc/NetworkManager/conf.d/99-custom-nm.conf
sudo systemctl reload NetworkManager

# 5. ZRAM
sudo cp ../rootfs/zram/*.conf /etc/systemd/zram-generator.conf.d/99-custom-zram.conf
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0