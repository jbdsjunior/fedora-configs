---

Após rodar os scripts e reiniciar o computador, use estes comandos para confirmar se tudo funcionou no Fedora 43:

**1. Verificar se o BBR (Aceleração de Internet) está ativo:**

```bash
sysctl net.ipv4.tcp_congestion_control
# Saída esperada: net.ipv4.tcp_congestion_control = bbr

```

**2. Verificar ZRAM (Memória Comprimida):**

```bash
zramctl
# Deve mostrar /dev/zram0 com algoritmo zstd e tamanho configurado.

```

**3. Verificar DNS Seguro:**

```bash
resolvectl status
# Verifique se "DNS over TLS" aparece como "opportunistic" na sua interface de rede.

```

**4. Verificar Diretório KVM (No_COW):**

```bash
lsattr -d /var/lib/libvirt/images
# A saída deve conter um 'C' maiúsculo, ex: ---------------C------

```
