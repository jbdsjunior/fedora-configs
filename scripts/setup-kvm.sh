#!/bin/bash
set -euo pipefail

# Variáveis
SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
USER_IMAGES_DIR="$HOME/.local/share/libvirt/images"

echo "--- Configurando KVM e Libvirt ---"

# 1. Adicionar usuário aos grupos (Comando único)
# Adiciona aos grupos libvirt, kvm e qemu de uma vez
echo "Adicionando $USER aos grupos..."
sudo usermod -aG libvirt,kvm,qemu "$USER"

# 2. Configurar Diretório do Sistema
echo "Configurando diretório de imagens do sistema..."
sudo mkdir -p "$SYSTEM_IMAGES_DIR"
sudo chmod 755 "$SYSTEM_IMAGES_DIR"

# Aplica No_COW (+C) se ainda não tiver (evita erro se não for BTRFS)
sudo chattr +C "$SYSTEM_IMAGES_DIR" || echo "Aviso: Não foi possível definir +C (FS não é BTRFS?)"

# 3. Configurar Diretório do Usuário
echo "Configurando diretório de imagens do usuário..."
mkdir -p "$USER_IMAGES_DIR"
chattr +C "$USER_IMAGES_DIR" || true

# 4. Reiniciar serviço
echo "Reiniciando libvirtd..."
if systemctl list-unit-files | grep -q libvirtd.service; then
    sudo systemctl restart libvirtd
else
    echo "Aviso: libvirtd não encontrado. Instale com: sudo dnf groupinstall @virtualization"
fi

echo "Pronto! Faça Logoff/Login para atualizar as permissões."