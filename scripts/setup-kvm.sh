#!/bin/bash
set -euo pipefail

# Variáveis
SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
USER_IMAGES_DIR="$HOME/.local/share/libvirt/images"

echo "--- Configurando KVM e Libvirt (Fedora) ---"

# 1. Adicionar usuário aos grupos
echo "[1/3] Adicionando $USER aos grupos de virtualização..."
# Tenta adicionar a grupos comuns. '|| true' evita falha se um grupo não existir.
sudo usermod -aG libvirt,kvm,qemu "$USER" || true

# 2. Configurar Diretório do Sistema (No_COW)
echo "[2/3] Configurando diretório de imagens do sistema..."
sudo mkdir -p "$SYSTEM_IMAGES_DIR"
sudo chmod 755 "$SYSTEM_IMAGES_DIR"

# Aplica atributo +C (No_COW) para performance em BTRFS
# O 'chattr' só funciona bem em pastas vazias ou arquivos novos.
if lsattr -d "$SYSTEM_IMAGES_DIR" 2>/dev/null | grep -q -- "-C-"; then
    echo "  -> Atributo No_COW (+C) já ativo."
else
    echo "  -> Aplicando atributo No_COW (+C)..."
    sudo chattr +C "$SYSTEM_IMAGES_DIR" || echo "  [!] Aviso: Não foi possível definir +C (FS não é BTRFS?)"
fi

# 3. Configurar Diretório do Usuário (No_COW)
echo "[3/3] Configurando diretório de imagens do usuário..."
mkdir -p "$USER_IMAGES_DIR"

if lsattr -d "$USER_IMAGES_DIR" 2>/dev/null | grep -q -- "-C-"; then
    echo "  -> Atributo No_COW (+C) já ativo no Home."
else
    echo "  -> Aplicando atributo No_COW (+C) no Home..."
    chattr +C "$USER_IMAGES_DIR" || true
fi

# 4. Reiniciar serviço
echo "-> Reiniciando libvirtd..."
if systemctl list-unit-files | grep -q libvirtd.service; then
    sudo systemctl restart libvirtd
    echo "Sucesso! Lembre-se de fazer LOGOFF/LOGIN para atualizar suas permissões de grupo."
else
    echo "Aviso: libvirtd não instalado. (sudo dnf groupinstall @virtualization)"
fi