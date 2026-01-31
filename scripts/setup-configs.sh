#!/bin/bash
set -euo pipefail

# Definição de caminhos
ROOTFS_ETC="../rootfs/etc"

echo "--- Iniciando Otimização Fedora Plasma ---"

# 1. Sysctl & Kernel (BBR, Performance, Inotify)
echo "[1/7] Aplicando Sysctl e Módulos..."
sudo cp "$ROOTFS_ETC/sysctl.d/"*.conf /etc/sysctl.d/
sudo cp "$ROOTFS_ETC/modules-load.d/"*.conf /etc/modules-load.d/
sudo sysctl --system
sudo modprobe tcp_bbr || true

# 2. Rede (DNS over TLS & NetworkManager)
echo "[2/7] Configurando DNS e Privacidade de Rede..."
sudo mkdir -p /etc/systemd/resolved.conf.d/ /etc/NetworkManager/conf.d/
sudo cp "$ROOTFS_ETC/systemd/resolved.conf.d/"*.conf /etc/systemd/resolved.conf.d/
sudo cp "$ROOTFS_ETC/NetworkManager/conf.d/"*.conf /etc/NetworkManager/conf.d/
sudo systemctl restart systemd-resolved
sudo systemctl reload NetworkManager

# 3. Virtualização e BTRFS (No_COW)
echo "[3/7] Configurando diretórios de VM..."
sudo mkdir -p /etc/tmpfiles.d/ /etc/user-tmpfiles.d/
sudo cp "$ROOTFS_ETC/tmpfiles.d/"*.conf /etc/tmpfiles.d/
sudo cp "$ROOTFS_ETC/user-tmpfiles.d/"*.conf /etc/user-tmpfiles.d/
sudo systemd-tmpfiles --create

# 4. Memória (ZRAM)
echo "[4/7] Otimizando ZRAM..."
sudo mkdir -p /etc/systemd/zram-generator.conf.d/
sudo cp "$ROOTFS_ETC/systemd/zram-generator.conf.d/"*.conf /etc/systemd/zram-generator.conf.d/
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0 || true

# 5. Interface e Shell (Fonts & Profile)
echo "[5/7] Ajustando Renderização e Shell..."
sudo mkdir -p /etc/fonts/conf.d/
sudo cp "$ROOTFS_ETC/fonts/conf.d/"*.conf /etc/fonts/conf.d/
sudo cp "$ROOTFS_ETC/profile.d/"*.conf /etc/profile.d/

# 6. Automação de Updates (Flatpak & DNF)
echo "[6/7] Configurando Gatilhos de Atualização..."
# Flatpak Update Trigger
sudo mkdir -p /etc/systemd/system/flatpak-system-update.timer.d/
sudo cp "$ROOTFS_ETC/systemd/system/flatpak-system-update.timer.d/override.conf" \
        /etc/systemd/system/flatpak-system-update.timer.d/custom-schedule.conf
sudo systemctl daemon-reload
sudo systemctl enable --now flatpak-system-update.timer

# Substituto para rpm-ostree automatic no Fedora tradicional
echo "Instalando dnf-automatic..."
sudo dnf install -y dnf-automatic
sudo systemctl enable --now dnf-automatic-install.timer

# 7. Serviços de Usuário (Templates)
echo "[7/7] Instalando templates de serviços (Rclone)..."
sudo mkdir -p /etc/systemd/user/
sudo cp "$ROOTFS_ETC/systemd/user/"*.service /etc/systemd/user/

echo "--- Setup concluído com sucesso! ---"