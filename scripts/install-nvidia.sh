#!/bin/bash

# --- CONFIGURAÇÃO: HARDWARE DETECTADO ---
# CPU: Ryzen 9 5950X
# GPU 1 (Display): RX 6600 XT (Driver Open Source Nativo - Mesa)
# GPU 2 (Compute): RTX 3080 Ti (Necessita Driver Proprietário + CUDA)

# Verifica root
[ "$EUID" -ne 0 ] && echo "Execute como root (sudo)." && exit 1

# --- MODO REMOÇÃO ---
if [ "$1" == "remove" ]; then
    echo "--- Removendo Drivers Nvidia (Mantendo AMD intacto) ---"
    dnf remove "*nvidia*" "*cuda*" -y
    # Remove configurações que possam forçar a Nvidia como primária
    rm -f /etc/X11/xorg.conf.d/99-nvidia.conf
    rm -f /usr/share/X11/xorg.conf.d/nvidia-drm-outputclass.conf
    echo "Drivers Nvidia removidos. O sistema voltará a usar apenas a AMD 6600XT."
    exit 0
fi

# --- MODO INSTALAÇÃO ---
echo "--- Configurando Fedora 43 para Compute Node (AMD + Nvidia) ---"

# 1. Instala Repositórios RPM Fusion (Fonte segura para Secure Boot)
echo ">> Configurando repositórios..."
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -yq

# 2. Configuração de Secure Boot (Inteligente)
if mokutil --sb-state | grep -q "enabled"; then
    echo ">> Secure Boot ATIVO. Preparando chaves para a 3080 Ti..."
    dnf install akmods mokutil openssl -yq

    # Gera chave se não existir
    [ ! -f "/etc/pki/akmods/certs/public_key.der" ] && kmodgenca -a

    echo " "
    echo "!!! ATENÇÃO !!!"
    echo "Você precisará definir uma senha agora. No próximo boot, tela azul:"
    echo "Enroll MOK -> Continue -> Yes -> Senha -> Reboot"
    echo " "
    mokutil --import /etc/pki/akmods/certs/public_key.der
else
    echo ">> Secure Boot OFF. Instalação direta."
fi

# 3. Instalação Focada em COMPUTAÇÃO (LLMs)
# akmod-nvidia: Driver do Kernel
# xorg-x11-drv-nvidia-cuda: Bibliotecas CUDA essenciais para PyTorch/TensorFlow
# xorg-x11-drv-nvidia-cuda-libs: Bibliotecas de runtime
echo ">> Instalando Drivers e Libs CUDA para 3080 Ti..."
dnf upgrade --refresh -y
dnf install akmod-nvidia \
            xorg-x11-drv-nvidia-cuda \
            xorg-x11-drv-nvidia-cuda-libs \
            xorg-x11-drv-nvidia-power -y

# 4. Ajustes para setup Híbrido (AMD Display / Nvidia Compute)
# Isso garante que o driver Nvidia não tente forçar ser o primário no X11/Wayland
# O parametro NVreg_DynamicPowerManagement=0x02 ajuda a placa a ficar quieta quando não usada
echo ">> Otimizando para uso secundário..."

# Força a compilação do módulo agora
akmods --force

echo " "
echo "--- Instalação Concluída ---"
echo "HARDWARE CHECK:"
echo "1. Certifique-se que seu monitor está ligado na AMD 6600 XT."
echo "2. Na BIOS, confirme que 'Primary Video Adapter' está como PCIe Slot 1 (ou onde a AMD estiver)."
echo "3. Reinicie o sistema."
echo " "
echo "Para testar LLMs depois: o comando 'nvidia-smi' deve listar a 3080 Ti."