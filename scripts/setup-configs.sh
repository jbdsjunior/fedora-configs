#!/bin/bash
set -euo pipefail

# Caminho dos arquivos de origem (ajuste se necessário)
ROOTFS_ETC="../rootfs/etc"

echo "--- Iniciando Otimização Fedora (Modo Linear) ---"

# -----------------------------------------------------------
# 1. Sysctl & Kernel (BBR, Performance)
# -----------------------------------------------------------
echo "[1/7] Aplicando Sysctl e Módulos..."

# Sysctl
sudo mkdir -p /etc/sysctl.d
sudo cp "$ROOTFS_ETC/sysctl.d/"*.conf /etc/sysctl.d/
sudo chmod 644 /etc/sysctl.d/*.conf

# Modules
sudo mkdir -p /etc/modules-load.d
sudo cp "$ROOTFS_ETC/modules-load.d/"*.conf /etc/modules-load.d/
sudo chmod 644 /etc/modules-load.d/*.conf

# Aplicar mudanças
sudo sysctl --system
sudo modprobe tcp_bbr || echo "Aviso: tcp_bbr não carregado (pode ser built-in)."

# -----------------------------------------------------------
# 2. Rede (DNS & NetworkManager)
# -----------------------------------------------------------
echo "[2/7] Configurando Rede..."

# Resolved (DNS)
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo cp "$ROOTFS_ETC/systemd/resolved.conf.d/"*.conf /etc/systemd/resolved.conf.d/
sudo chmod 644 /etc/systemd/resolved.conf.d/*.conf

# NetworkManager
sudo mkdir -p /etc/NetworkManager/conf.d
sudo cp "$ROOTFS_ETC/NetworkManager/conf.d/"*.conf /etc/NetworkManager/conf.d/
sudo chmod 644 /etc/NetworkManager/conf.d/*.conf

# Reiniciar serviços
sudo systemctl restart systemd-resolved
sudo systemctl reload NetworkManager

# -----------------------------------------------------------
# 3. Virtualização e BTRFS (Tmpfiles)
# -----------------------------------------------------------
echo "[3/7] Configurando tmpfiles (No_COW)..."

# System tmpfiles
sudo mkdir -p /etc/tmpfiles.d
sudo cp "$ROOTFS_ETC/tmpfiles.d/"*.conf /etc/tmpfiles.d/
sudo chmod 644 /etc/tmpfiles.d/*.conf

# User tmpfiles
sudo mkdir -p /etc/user-tmpfiles.d
sudo cp "$ROOTFS_ETC/user-tmpfiles.d/"*.conf /etc/user-tmpfiles.d/
sudo chmod 644 /etc/user-tmpfiles.d/*.conf

# Aplicar
sudo systemd-tmpfiles --create

# -----------------------------------------------------------
# 4. Memória (ZRAM)
# -----------------------------------------------------------
echo "[4/7] Otimizando ZRAM..."

sudo mkdir -p /etc/systemd/zram-generator.conf.d
sudo cp "$ROOTFS_ETC/systemd/zram-generator.conf.d/"*.conf /etc/systemd/zram-generator.conf.d/
sudo chmod 644 /etc/systemd/zram-generator.conf.d/*.conf

sudo systemctl daemon-reload
sudo systemctl start /dev/zram0 || true

# -----------------------------------------------------------
# 5. Interface e Shell
# -----------------------------------------------------------
echo "[5/7] Ajustando Shell e Fontes..."

# Fontes
sudo mkdir -p /etc/fonts/conf.d
sudo cp "$ROOTFS_ETC/fonts/conf.d/"*.conf /etc/fonts/conf.d/
sudo chmod 644 /etc/fonts/conf.d/*.conf

# Shell Profile (CORREÇÃO: alterado de *.conf para *.sh)
sudo mkdir -p /etc/profile.d
sudo cp "$ROOTFS_ETC/profile.d/"*.sh /etc/profile.d/
sudo chmod 644 /etc/profile.d/*.sh

# -----------------------------------------------------------
# 6. Automação de Updates
# -----------------------------------------------------------
echo "[6/7] Configurando Updates..."

# Flatpak Timer (CORREÇÃO: nome do arquivo destino corrigido)
sudo mkdir -p /etc/systemd/system/flatpak-system-update.timer.d/
sudo cp "$ROOTFS_ETC/systemd/system/flatpak-system-update.timer.d/custom-schedule.conf" \
        "/etc/systemd/system/flatpak-system-update.timer.d/custom-schedule.conf"
sudo chmod 644 "/etc/systemd/system/flatpak-system-update.timer.d/custom-schedule.conf"

sudo systemctl daemon-reload
sudo systemctl enable --now flatpak-system-update.timer

# DNF Automatic (apenas se dnf existir)
if command -v dnf &> /dev/null; then
    echo "Instalando dnf-automatic..."
    sudo dnf install -y dnf-automatic
    sudo systemctl enable --now dnf-automatic.timer
fi

# -----------------------------------------------------------
# 7. Serviços de Usuário (Rclone)
# -----------------------------------------------------------
echo "[7/7] Instalando Templates de Serviço..."

sudo mkdir -p /etc/systemd/user
sudo cp "$ROOTFS_ETC/systemd/user/"*.service /etc/systemd/user/
sudo chmod 644 /etc/systemd/user/*.service

echo "--- Setup concluído! Reinicie o sistema. ---"