#!/bin/bash
set -euo pipefail

# Definição de caminhos
ROOTFS_ETC="../rootfs/etc"

echo "--- Iniciando Otimização Fedora Workstation (Compatível F43+) ---"

# -----------------------------------------------------------
# 1. Sysctl & Kernel (BBR, Performance)
# -----------------------------------------------------------
echo "[1/7] Aplicando Otimizações de Kernel e Sysctl..."

# Sysctl
sudo mkdir -p /etc/sysctl.d
sudo cp "$ROOTFS_ETC/sysctl.d/"*.conf /etc/sysctl.d/
sudo chmod 644 /etc/sysctl.d/*.conf

# Modules (BBR)
sudo mkdir -p /etc/modules-load.d
sudo cp "$ROOTFS_ETC/modules-load.d/"*.conf /etc/modules-load.d/
sudo chmod 644 /etc/modules-load.d/*.conf

# Aplicar mudanças
echo "  -> Carregando parâmetros..."
sudo sysctl --system > /dev/null
sudo modprobe tcp_bbr || echo "  [!] Aviso: tcp_bbr não carregado (pode ser built-in no kernel F43)."

# -----------------------------------------------------------
# 2. Rede (DNS & NetworkManager)
# -----------------------------------------------------------
echo "[2/7] Configurando Privacidade e DNS..."

# Resolved (DNS)
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo cp "$ROOTFS_ETC/systemd/resolved.conf.d/"*.conf /etc/systemd/resolved.conf.d/
sudo chmod 644 /etc/systemd/resolved.conf.d/*.conf

# NetworkManager
sudo mkdir -p /etc/NetworkManager/conf.d
sudo cp "$ROOTFS_ETC/NetworkManager/conf.d/"*.conf /etc/NetworkManager/conf.d/
sudo chmod 644 /etc/NetworkManager/conf.d/*.conf

# Reiniciar serviços
echo "  -> Reiniciando NetworkManager e Resolved..."
sudo systemctl restart systemd-resolved
sudo systemctl reload NetworkManager

# -----------------------------------------------------------
# 3. Virtualização e BTRFS (No_COW)
# -----------------------------------------------------------
echo "[3/7] Configurando tmpfiles (Performance BTRFS)..."

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

# Shell Profile (Corrigido extensão .sh)
sudo mkdir -p /etc/profile.d
sudo cp "$ROOTFS_ETC/profile.d/"*.sh /etc/profile.d/
sudo chmod 644 /etc/profile.d/*.sh

# -----------------------------------------------------------
# 6. Automação de Updates (Detecção DNF4 vs DNF5)
# -----------------------------------------------------------
echo "[6/7] Configurando Updates Automáticos..."

# DNF: Detecta se é DNF5 (Fedora 41+) ou DNF4 e ativa o correto
if command -v dnf5 &> /dev/null; then
    echo "  -> Detectado DNF5. Instalando plugin..."
    sudo dnf install -y dnf5-plugin-automatic || true
    # Tenta ativar o timer (o nome pode variar, tentamos o padrão)
    sudo systemctl enable --now dnf5-automatic.timer || echo "  [!] Aviso: Verifique o nome do timer dnf5 (ex: dnf5-automatic.timer)"
elif command -v dnf &> /dev/null; then
    echo "  -> Detectado DNF4. Configurando dnf-automatic..."
    sudo dnf install -y dnf-automatic
    sudo systemctl enable --now dnf-automatic.timer
fi

# -----------------------------------------------------------
# 7. Serviços de Usuário (Rclone)
# -----------------------------------------------------------
echo "[7/7] Instalando Templates de Serviço (Rclone)..."

sudo mkdir -p /etc/systemd/user
# Copia o arquivo corrigido (verifique se você atualizou o conteúdo do arquivo rclone antes!)
sudo cp "$ROOTFS_ETC/systemd/user/"*.service /etc/systemd/user/
sudo chmod 644 /etc/systemd/user/*.service

echo "--- Setup concluído! Reinicie o computador. ---"