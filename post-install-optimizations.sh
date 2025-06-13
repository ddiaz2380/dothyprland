#!/bin/bash

# =============================================================================
# POST-INSTALACIÓN Y OPTIMIZACIONES ARCH LINUX + HYPRLAND
# Script para optimizaciones y configuraciones adicionales
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "\n${PURPLE}==> $1${NC}"
}

# =============================================================================
# OPTIMIZACIONES DEL SISTEMA
# =============================================================================

optimize_pacman() {
    print_step "Optimizando Pacman"
    
    # Backup de configuración original
    sudo cp /etc/pacman.conf /etc/pacman.conf.backup
    
    # Configurar pacman para mejor rendimiento
    sudo tee /etc/pacman.conf > /dev/null << 'EOF'
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
ParallelDownloads = 10
ILoveCandy

SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

    # Actualizar mirrors para mejor velocidad
    sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    print_status "Pacman optimizado"
}

optimize_zram() {
    print_step "Configurando ZRAM para mejor rendimiento de memoria"
    
    # Instalar zram-generator
    yay -S --noconfirm zram-generator
    
    # Configurar zram
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF

    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service
    sudo systemctl enable systemd-zram-setup@zram0.service
    
    print_status "ZRAM configurado"
}

optimize_kernel_parameters() {
    print_step "Optimizando parámetros del kernel"
    
    # Configurar parámetros del kernel para mejor rendimiento
    sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'EOF'
# Optimizaciones de memoria
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Optimizaciones de red
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Optimizaciones del sistema de archivos
kernel.sched_autogroup_enabled = 0
kernel.sched_cfs_bandwidth_slice_us = 3000
EOF

    print_status "Parámetros del kernel optimizados"
}

setup_gaming_optimizations() {
    print_step "Configurando optimizaciones para gaming"
    
    # Instalar GameMode
    yay -S --noconfirm gamemode lib32-gamemode
    
    # Configurar GameMode
    sudo tee /etc/security/limits.conf >> /dev/null << 'EOF'
@gamemode   -   nice        -10
@gamemode   -   rtprio      20
EOF

    # Añadir usuario al grupo gamemode
    sudo usermod -aG gamemode $USER
    
    # Instalar MangoHud para overlay de rendimiento
    yay -S --noconfirm mangohud lib32-mangohud
    
    print_status "Optimizaciones de gaming configuradas"
}

# =============================================================================
# CONFIGURACIONES ESPECÍFICAS DE HYPRLAND
# =============================================================================

setup_hyprland_optimizations() {
    print_step "Aplicando optimizaciones específicas de Hyprland"
    
    # Crear configuración optimizada de Hyprland
    mkdir -p ~/.config/hypr/conf.d
    
    # Configuración de rendimiento
    tee ~/.config/hypr/conf.d/performance.conf > /dev/null << 'EOF'
# Optimizaciones de rendimiento para Hyprland
decoration {
    drop_shadow = false  # Desactivar sombras para mejor rendimiento
    blur {
        enabled = true
        size = 2  # Reducir tamaño de blur
        passes = 1  # Reducir pasadas de blur
        new_optimizations = true
    }
}

# Configuración de renderizado
render {
    explicit_sync = 1
    explicit_sync_kms = 1
    direct_scanout = true
}

# Optimizaciones de animaciones
animations {
    enabled = true
    bezier = wind, 0.2, 0.8, 0.2, 1.0
    animation = windows, 1, 4, wind, slide
    animation = windowsIn, 1, 4, wind, slide
    animation = windowsOut, 1, 4, wind, slide
    animation = fade, 1, 6, default
    animation = workspaces, 1, 4, wind
}

# Configuración de entrada optimizada
input {
    force_no_accel = true  # Desactivar aceleración del mouse para gaming
}
EOF

    # Incluir configuración de rendimiento en hyprland.conf
    echo "source = ~/.config/hypr/conf.d/performance.conf" >> ~/.config/hypr/hyprland.conf
    
    print_status "Optimizaciones de Hyprland aplicadas"
}

setup_wallpaper_management() {
    print_step "Configurando gestión de wallpapers"
    
    # Crear directorio de wallpapers
    mkdir -p ~/Pictures/wallpapers
    
    # Script para cambio automático de wallpapers
    tee ~/Scripts/wallpaper-manager > /dev/null << 'EOF'
#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CURRENT_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

change_wallpaper() {
    if [ ! -d "$WALLPAPER_DIR" ]; then
        notify-send "Error" "Directorio de wallpapers no encontrado"
        exit 1
    fi
    
    # Buscar wallpapers
    wallpapers=($(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \)))
    
    if [ ${#wallpapers[@]} -eq 0 ]; then
        notify-send "Error" "No se encontraron wallpapers"
        exit 1
    fi
    
    # Seleccionar wallpaper aleatorio
    random_wallpaper=${wallpapers[$RANDOM % ${#wallpapers[@]}]}
    
    # Cambiar wallpaper con swww
    swww img "$random_wallpaper" --transition-fps 60 --transition-type wipe --transition-duration 1
    
    # Guardar wallpaper actual
    echo "$random_wallpaper" > "$CURRENT_WALLPAPER_FILE"
    
    notify-send "Wallpaper" "Cambiado a: $(basename "$random_wallpaper")"
}

case "$1" in
    "change"|"random")
        change_wallpaper
        ;;
    "current")
        if [ -f "$CURRENT_WALLPAPER_FILE" ]; then
            cat "$CURRENT_WALLPAPER_FILE"
        fi
        ;;
    *)
        echo "Uso: $0 {change|random|current}"
        exit 1
        ;;
esac
EOF

    chmod +x ~/Scripts/wallpaper-manager
    
    # Crear servicio systemd para cambio automático de wallpaper
    mkdir -p ~/.config/systemd/user
    
    tee ~/.config/systemd/user/wallpaper-changer.service > /dev/null << 'EOF'
[Unit]
Description=Automatic wallpaper changer
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/Scripts/wallpaper-manager change

[Install]
WantedBy=default.target
EOF

    tee ~/.config/systemd/user/wallpaper-changer.timer > /dev/null << 'EOF'
[Unit]
Description=Change wallpaper every 30 minutes
Requires=wallpaper-changer.service

[Timer]
OnUnitActiveSec=30min
OnBootSec=1min

[Install]
WantedBy=timers.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable wallpaper-changer.timer
    
    print_status "Gestión de wallpapers configurada"
}

# =============================================================================
# CONFIGURACIONES DE DESARROLLO
# =============================================================================

setup_development_environment() {
    print_step "Configurando entorno de desarrollo avanzado"
    
    # Configurar Git globalmente
    read -p "Ingresa tu nombre para Git: " git_name
    read -p "Ingresa tu email para Git: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor nvim
    git config --global pull.rebase true
    git config --global push.default current
    git config --global diff.tool vimdiff
    git config --global merge.tool vimdiff
    
    # Configurar fnm y instalar versiones de Node.js
    print_status "Configurando fnm y Node.js"
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
    
    # Verificar si las versiones ya están instaladas
    if ! fnm list | grep -q "v18"; then
        fnm install 18
    fi
    if ! fnm list | grep -q "v20"; then
        fnm install 20
    fi
    if ! fnm list | grep -q "v22"; then
        fnm install 22
    fi
    
    fnm use 20
    fnm default 20
    
    # Instalar herramientas globales de Node.js
    npm install -g \
        yarn \
        pnpm \
        typescript \
        ts-node \
        @angular/cli \
        @vue/cli \
        create-react-app \
        vite \
        eslint \
        prettier \
        nodemon \
        pm2 \
        http-server \
        live-server
    
    # Configurar pyenv y instalar versiones de Python
    print_status "Configurando pyenv y Python"
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    
    # Instalar versiones de Python si no están instaladas
    python_versions=("3.9.18" "3.10.13" "3.11.7" "3.12.1" "3.13.0")
    for version in "${python_versions[@]}"; do
        if ! pyenv versions | grep -q "$version"; then
            print_status "Instalando Python $version"
            pyenv install "$version"
        fi
    done
    
    pyenv global 3.11.7
    
    # Instalar herramientas adicionales de desarrollo
    yay -S --noconfirm \
        github-cli \
        code \
        postman-bin \
        dbeaver \
        redis \
        postgresql \
        mysql \
        mongodb-bin \
        docker-desktop \
        kubernetes-cli \
        helm \
        terraform \
        ansible \
        vagrant
    
    # Configurar Docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    # Instalar herramientas de Python
    pip install --user \
        virtualenv \
        virtualenvwrapper \
        poetry \
        pipenv \
        black \
        flake8 \
        pylint \
        pytest \
        jupyter \
        ipython \
        requests \
        fastapi \
        django \
        flask
    
    # Configurar Rust y herramientas
    print_status "Configurando Rust"
    rustup component add rustfmt clippy rust-analyzer
    cargo install \
        cargo-watch \
        cargo-edit \
        cargo-expand \
        cargo-audit \
        exa \
        bat \
        ripgrep \
        fd-find \
        dust \
        procs \
        bandwhich
    
    # Configurar Go
    print_status "Configurando Go"
    go install github.com/air-verse/air@latest
    go install github.com/cosmtrek/air@latest
    go install golang.org/x/tools/gopls@latest
    go install github.com/go-delve/delve/cmd/dlv@latest
    
    print_status "Entorno de desarrollo avanzado configurado"
}

setup_multimedia_codecs() {
    print_step "Instalando codecs multimedia completos"
    
    yay -S --noconfirm \
        gstreamer \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \
        gst-libav \
        x264 \
        x265 \
        libde265 \
        libheif \
        libjxl \
        libavif \
        webkit2gtk \
        phonon-qt5-gstreamer \
        phonon-qt6-gstreamer
    
    print_status "Codecs multimedia instalados"
}

# =============================================================================
# CONFIGURACIONES DE SEGURIDAD
# =============================================================================

setup_security() {
    print_step "Configurando seguridad del sistema"
    
    # Instalar y configurar firewall
    yay -S --noconfirm ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
    
    # Instalar ClamAV (antivirus)
    yay -S --noconfirm clamav
    sudo freshclam
    sudo systemctl enable clamav-freshclam
    
    # Configurar fail2ban
    yay -S --noconfirm fail2ban
    sudo systemctl enable fail2ban
    
    # Configuración de SSH más segura
    if [ -f /etc/ssh/sshd_config ]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        
        sudo tee -a /etc/ssh/sshd_config > /dev/null << 'EOF'

# Configuraciones de seguridad adicionales
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
    fi
    
    print_status "Seguridad del sistema configurada"
}

# =============================================================================
# LIMPIEZA Y OPTIMIZACIÓN FINAL
# =============================================================================

final_cleanup() {
    print_step "Realizando limpieza final"
    
    # Limpiar cache de pacman
    yay -Scc --noconfirm
    
    # Limpiar logs antiguos
    sudo journalctl --vacuum-time=2weeks
    
    # Limpiar archivos temporales
    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*
    
    # Optimizar base de datos de pacman
    sudo pacman-db-upgrade
    
    # Reconstruir initramfs
    sudo mkinitcpio -P
    
    # Actualizar grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    print_status "Limpieza completada"
}

create_maintenance_scripts() {
    print_step "Creando scripts de mantenimiento"
    
    # Script de actualización del sistema
    tee ~/Scripts/update-system > /dev/null << 'EOF'
#!/bin/bash
echo "Actualizando mirrors..."
sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "Actualizando sistema..."
yay -Syu --noconfirm

echo "Limpiando cache..."
yay -Sc --noconfirm

echo "Actualizando base de datos de archivos..."
sudo updatedb

echo "¡Sistema actualizado!"
EOF

    # Script de limpieza del sistema
    tee ~/Scripts/clean-system > /dev/null << 'EOF'
#!/bin/bash
echo "Limpiando cache de pacman..."
yay -Scc --noconfirm

echo "Limpiando logs..."
sudo journalctl --vacuum-time=1week

echo "Limpiando archivos temporales..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo "Limpiando cache de usuario..."
rm -rf ~/.cache/*

echo "¡Sistema limpiado!"
EOF

    chmod +x ~/Scripts/update-system
    chmod +x ~/Scripts/clean-system
    
    print_status "Scripts de mantenimiento creados"
}

# =============================================================================
# MENÚ PRINCIPAL
# =============================================================================

show_post_install_menu() {
    while true; do
        clear
        echo -e "${CYAN}POST-INSTALACIÓN Y OPTIMIZACIONES${NC}"
        echo -e "${WHITE}====================================${NC}"
        echo
        echo -e "${GREEN}1.${NC}  Optimizar Pacman"
        echo -e "${GREEN}2.${NC}  Configurar ZRAM"
        echo -e "${GREEN}3.${NC}  Optimizar parámetros del kernel"
        echo -e "${GREEN}4.${NC}  Configurar optimizaciones gaming"
        echo -e "${GREEN}5.${NC}  Optimizar Hyprland"
        echo -e "${GREEN}6.${NC}  Configurar gestión de wallpapers"
        echo -e "${GREEN}7.${NC}  Configurar entorno de desarrollo"
        echo -e "${GREEN}8.${NC}  Instalar codecs multimedia"
        echo -e "${GREEN}9.${NC}  Configurar seguridad"
        echo -e "${GREEN}10.${NC} Crear scripts de mantenimiento"
        echo -e "${GREEN}11.${NC} Limpieza final"
        echo -e "${GREEN}12.${NC} Aplicar todas las optimizaciones"
        echo -e "${GREEN}0.${NC}  Salir"
        echo
        
        read -p "$(echo -e "${CYAN}Selecciona una opción: ${NC}")" choice
        
        case $choice in
            1) optimize_pacman ;;
            2) optimize_zram ;;
            3) optimize_kernel_parameters ;;
            4) setup_gaming_optimizations ;;
            5) setup_hyprland_optimizations ;;
            6) setup_wallpaper_management ;;
            7) setup_development_environment ;;
            8) setup_multimedia_codecs ;;
            9) setup_security ;;
            10) create_maintenance_scripts ;;
            11) final_cleanup ;;
            12) 
                optimize_pacman
                optimize_zram
                optimize_kernel_parameters
                setup_gaming_optimizations
                setup_hyprland_optimizations
                setup_wallpaper_management
                setup_development_environment
                setup_multimedia_codecs
                setup_security
                create_maintenance_scripts
                final_cleanup
                ;;
            0) exit 0 ;;
            *) echo "Opción inválida" ;;
        esac
        
        read -p "Presiona Enter para continuar..."
    done
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    echo -e "${CYAN}POST-INSTALACIÓN ARCH LINUX + HYPRLAND${NC}"
    echo -e "${WHITE}=====================================${NC}"
    echo
    echo "Este script aplicará optimizaciones y configuraciones adicionales"
    echo "para mejorar el rendimiento y la experiencia del usuario."
    echo
    
    if ! command -v yay &> /dev/null; then
        print_status "Instalando yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
    fi
    
    show_post_install_menu
}

main "$@"
