#!/bin/bash
set -euo pipefail

# Caminho base para os arquivos de configuração (relativo ao diretório scripts/)
ROOTFS="../rootfs/etc"

echo "Iniciando a aplicação das configurações customizadas..."

# 1. Sysctl (Kernel e Performance)
# Consolida as várias otimizações em arquivos no diretório de destino
echo "Aplicando otimizações de Kernel (Sysctl)..."
sudo cp "$ROOTFS/sysctl.d/"*.conf /etc/sysctl.d/
sudo sysctl --system

# 2. DNS Over TLS (Systemd-Resolved)
echo "Configurando DNS Over TLS..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo cp "$ROOTFS/systemd/resolved.conf.d/dns-override.conf" /etc/systemd/resolved.conf.d/custom-dns.conf
sudo systemctl restart systemd-resolved

# 3. Virtualização e BTRFS (No_COW)
echo "Configurando diretórios de VM (No_COW)..."
sudo cp "$ROOTFS/tmpfiles.d/10-kvm-images.conf" /etc/tmpfiles.d/custom-kvm.conf
# Para o usuário, usamos o diretório padrão do sistema para user-tmpfiles
sudo mkdir -p /etc/user-tmpfiles.d/
sudo cp "$ROOTFS/user-tmpfiles.d/kvm-user-images.conf" /etc/user-tmpfiles.d/custom-kvm-user.conf
sudo systemd-tmpfiles --create

# 4. NetworkManager (Privacidade e MAC Randomization)
echo "Configurando NetworkManager..."
sudo cp "$ROOTFS/NetworkManager/conf.d/"*.conf /etc/NetworkManager/conf.d/
sudo systemctl reload NetworkManager

# 5. ZRAM Otimizado
echo "Configurando ZRAM..."
sudo mkdir -p /etc/systemd/zram-generator.conf.d/
sudo cp "$ROOTFS/systemd/zram-generator.conf.d/99-optimization.conf" /etc/systemd/zram-generator.conf.d/custom-zram.conf
sudo systemctl daemon-reload
# O zram-generator criará o dispositivo automaticamente no próximo boot ou via start
sudo systemctl start /dev/zram0 || true

# 6. Módulos de Kernel (BBR)
echo "Habilitando módulo TCP BBR..."
sudo cp "$ROOTFS/modules-load.d/bbr.conf" /etc/modules-load.d/custom-bbr.conf
sudo modprobe tcp_bbr || true

# 7. Shell e Fontes (Global)
echo "Aplicando configurações de Shell e Renderização de Fontes..."
sudo cp "$ROOTFS/profile.d/99-custom-shell.sh" /etc/profile.d/
sudo mkdir -p /etc/fonts/conf.d/
sudo cp "$ROOTFS/fonts/conf.d/99-rendering-tweaks.conf" /etc/fonts/conf.d/

# 8. Serviços de Usuário (Rclone)
echo "Copiando templates de serviços de usuário (Rclone)..."
sudo mkdir -p /etc/systemd/user/
sudo cp "$ROOTFS/systemd/user/rclone-mount@.service" /etc/systemd/user/

echo "Configurações aplicadas com sucesso!"
echo "Algumas alterações podem exigir reinicialização para surtir efeito total."