#!/bin/bash

# =============================================================================
# ARCH LINUX + HYPRLAND INSTALLATION SCRIPT
# Script de instalación completo y modular para Arch Linux con Hyprland
# Basado en la configuración de dotfiles personalizada
# =============================================================================

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch-hyprland-install.log"
USER_NAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
HOSTNAME=""
TIMEZONE=""
LOCALE="es_ES.UTF-8"
KEYMAP="es"
DISK=""

# =============================================================================
# FUNCIONES UTILITARIAS
# =============================================================================

print_logo() {
    clear
    echo -e "${CYAN}"
    echo "██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ "
    echo "██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
    echo "███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║"
    echo "██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║"
    echo "██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝"
    echo "╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "${NC}"
    echo -e "${WHITE}==============================================================================${NC}"
    echo -e "${GREEN}  ARCH LINUX + HYPRLAND - INSTALADOR AUTOMATIZADO COMPLETO${NC}"
    echo -e "${WHITE}==============================================================================${NC}"
    echo -e "${YELLOW}  Basado en configuración de dotfiles personalizada${NC}"
    echo -e "${YELLOW}  Instalación modular con selección de componentes${NC}"
    echo -e "${WHITE}==============================================================================${NC}"
    echo
}

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    log "INFO: $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

print_step() {
    echo -e "\n${PURPLE}==> $1${NC}"
    log "STEP: $1"
}

ask_confirmation() {
    while true; do
        read -p "$(echo -e "${CYAN}$1 [s/n]: ${NC}")" yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor responde sí o no.";;
        esac
    done
}

check_internet() {
    print_step "Verificando conexión a internet"
    if ping -c 1 google.com &> /dev/null; then
        print_status "Conexión a internet: OK"
    else
        print_error "No hay conexión a internet. Conectarse antes de continuar."
        exit 1
    fi
}

check_uefi() {
    print_step "Verificando modo de arranque"
    if [ -d /sys/firmware/efi ]; then
        print_status "Sistema arrancado en modo UEFI"
        return 0
    else
        print_warning "Sistema arrancado en modo BIOS/Legacy"
        return 1
    fi
}

# =============================================================================
# CONFIGURACIÓN INICIAL
# =============================================================================

get_user_input() {
    print_step "Configuración inicial del sistema"
    
    echo -e "${CYAN}Ingresa la información del sistema:${NC}"
    
    while [[ -z "$USER_NAME" ]]; do
        read -p "Nombre de usuario: " USER_NAME
    done
    
    while [[ -z "$USER_PASSWORD" ]]; do
        read -s -p "Contraseña del usuario: " USER_PASSWORD
        echo
    done
    
    while [[ -z "$ROOT_PASSWORD" ]]; do
        read -s -p "Contraseña de root: " ROOT_PASSWORD
        echo
    done
    
    while [[ -z "$HOSTNAME" ]]; do
        read -p "Nombre del equipo (hostname): " HOSTNAME
    done
    
    echo -e "\n${CYAN}Configuración regional:${NC}"
    echo "Zona horaria por defecto: America/Mexico_City"
    read -p "Presiona Enter para usar la por defecto o ingresa otra: " user_timezone
    TIMEZONE=${user_timezone:-"America/Mexico_City"}
    
    echo "Distribución de teclado por defecto: es"
    read -p "Presiona Enter para usar la por defecto o ingresa otra: " user_keymap
    KEYMAP=${user_keymap:-"es"}
    
    print_status "Configuración guardada"
}

select_disk() {
    print_step "Selección del disco para instalación"
    
    echo -e "${YELLOW}Discos disponibles:${NC}"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    
    echo -e "\n${RED}¡ADVERTENCIA! El disco seleccionado será completamente borrado${NC}"
    
    while [[ -z "$DISK" ]]; do
        read -p "Ingresa el disco (ej: sda, nvme0n1): " DISK
        if [[ ! -b "/dev/$DISK" ]]; then
            print_error "El disco /dev/$DISK no existe"
            DISK=""
        fi
    done
    
    print_warning "Disco seleccionado: /dev/$DISK"
    if ! ask_confirmation "¿Estás seguro de continuar? Se borrará todo el contenido"; then
        exit 1
    fi
}

# =============================================================================
# PARTICIONADO Y FORMATEO
# =============================================================================

partition_disk() {
    print_step "Particionando disco /dev/$DISK"
    
    # Limpiar el disco
    wipefs -af /dev/$DISK
    sgdisk --zap-all /dev/$DISK
    
    if check_uefi; then
        # Crear particiones UEFI
        print_status "Creando particiones UEFI"
        sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI System" /dev/$DISK
        sgdisk -n 2:0:+4G -t 2:8200 -c 2:"Linux Swap" /dev/$DISK
        sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Root" /dev/$DISK
        
        # Variables de particiones
        if [[ $DISK =~ nvme ]]; then
            PART_EFI="/dev/${DISK}p1"
            PART_SWAP="/dev/${DISK}p2"
            PART_ROOT="/dev/${DISK}p3"
        else
            PART_EFI="/dev/${DISK}1"
            PART_SWAP="/dev/${DISK}2"
            PART_ROOT="/dev/${DISK}3"
        fi
        
        # Formatear particiones
        print_status "Formateando particiones"
        mkfs.fat -F32 "$PART_EFI"
        mkswap "$PART_SWAP"
        mkfs.ext4 "$PART_ROOT"
        
        # Montar particiones
        print_status "Montando particiones"
        mount "$PART_ROOT" /mnt
        mkdir -p /mnt/boot
        mount "$PART_EFI" /mnt/boot
        swapon "$PART_SWAP"
    else
        # Crear particiones BIOS
        print_status "Creando particiones BIOS/Legacy"
        sgdisk -n 1:0:+1M -t 1:ef02 -c 1:"BIOS Boot" /dev/$DISK
        sgdisk -n 2:0:+4G -t 2:8200 -c 2:"Linux Swap" /dev/$DISK
        sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Root" /dev/$DISK
        
        # Variables de particiones
        if [[ $DISK =~ nvme ]]; then
            PART_BIOS="/dev/${DISK}p1"
            PART_SWAP="/dev/${DISK}p2"
            PART_ROOT="/dev/${DISK}p3"
        else
            PART_BIOS="/dev/${DISK}1"
            PART_SWAP="/dev/${DISK}2"
            PART_ROOT="/dev/${DISK}3"
        fi
        
        # Formatear particiones
        print_status "Formateando particiones"
        mkswap "$PART_SWAP"
        mkfs.ext4 "$PART_ROOT"
        
        # Montar particiones
        print_status "Montando particiones"
        mount "$PART_ROOT" /mnt
        swapon "$PART_SWAP"
    fi
    
    print_status "Particionado completado"
}

# =============================================================================
# INSTALACIÓN DEL SISTEMA BASE
# =============================================================================

install_base_system() {
    print_step "Instalando sistema base"
    
    # Actualizar keyring
    pacman -Sy --noconfirm archlinux-keyring
    
    # Instalar sistema base
    print_status "Instalando paquetes base"
    pacstrap /mnt base base-devel linux linux-firmware networkmanager \
        grub efibootmgr dosfstools os-prober mtools \
        git vim nano wget curl sudo zsh tmux \
        intel-ucode amd-ucode
    
    # Generar fstab
    print_status "Generando fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
    
    print_status "Sistema base instalado"
}

configure_base_system() {
    print_step "Configurando sistema base"
    
    # Configurar en chroot
    arch-chroot /mnt /bin/bash << EOF
# Configurar zona horaria
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Configurar localización
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Configurar hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOL
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

# Configurar contraseñas
echo "root:$ROOT_PASSWORD" | chpasswd

# Crear usuario
useradd -mG wheel,audio,video,optical,storage -s /bin/zsh $USER_NAME
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# Configurar sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Habilitar servicios
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

EOF

    print_status "Sistema base configurado"
}

install_bootloader() {
    print_step "Instalando bootloader"
    
    arch-chroot /mnt /bin/bash << EOF
if [ -d /sys/firmware/efi ]; then
    # UEFI
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    # BIOS
    grub-install --target=i386-pc /dev/$DISK
fi

grub-mkconfig -o /boot/grub/grub.cfg
EOF

    print_status "Bootloader instalado"
}

# =============================================================================
# MÓDULOS DE INSTALACIÓN
# =============================================================================

install_hyprland_base() {
    print_step "Instalando Hyprland y dependencias base"
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Instalar yay (AUR helper)
cd /tmp
sudo -u $USER_NAME git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $USER_NAME makepkg -si --noconfirm
cd /

# Instalar Hyprland y dependencias básicas
sudo -u $USER_NAME yay -S --noconfirm \
    hyprland-git \
    waybar-hyprland-git \
    wofi \
    mako \
    swww \
    hyprlock \
    hypridle \
    hyprpicker \
    wlogout \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland

EOF

    print_status "Hyprland base instalado"
}

install_terminal_tools() {
    print_step "Instalando herramientas de terminal"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm \
    kitty \
    ranger \
    neovim \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    starship \
    btop \
    fastfetch \
    bat \
    duf \
    fzf \
    ripgrep \
    fd \
    exa \
    tree \
    unzip \
    zip \
    p7zip \
    tmux \
    w3m \
    atool \
    unrar \
    highlight \
    mediainfo \
    ffmpegthumbnailer \
    poppler \
    odt2txt \
    python-chardet \
    python-pillow

EOF

    print_status "Herramientas de terminal instaladas"
}

install_multimedia_tools() {
    print_step "Instalando herramientas multimedia"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    pamixer \
    playerctl \
    grim \
    slurp \
    grimblast-git \
    flameshot \
    obs-studio \
    mpv \
    ffmpeg \
    imagemagick

EOF

    print_status "Herramientas multimedia instaladas"
}

install_development_tools() {
    print_step "Instalando herramientas de desarrollo"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm \
    docker \
    docker-compose \
    python \
    python-pip \
    fnm-bin \
    yarn \
    rustup \
    go \
    lazygit \
    lazydocker \
    pyenv

# Configurar Rust
sudo -u $USER_NAME rustup default stable

# Configurar fnm para Node.js
sudo -u $USER_NAME bash -c '
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
fnm install 18
fnm install 20
fnm install 22
fnm use 20
fnm default 20
'

# Configurar pyenv para Python
sudo -u $USER_NAME bash -c '
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
pyenv install 3.9.18
pyenv install 3.10.13
pyenv install 3.11.7
pyenv install 3.12.1
pyenv install 3.13.0
pyenv global 3.11.7
'

# Añadir usuario al grupo docker
usermod -aG docker $USER_NAME

systemctl enable docker

EOF

    print_status "Herramientas de desarrollo instaladas"
}

install_applications() {
    print_step "Instalando aplicaciones"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm \
    firefox \
    google-chrome \
    obsidian \
    visual-studio-code-bin \
    sublime-text-4 \
    spotify \
    discord \
    telegram-desktop \
    neomutt \
    thunderbird \
    libreoffice-fresh \
    gimp \
    inkscape \
    vlc \
    blender \
    kdenlive \
    audacity

EOF

    print_status "Aplicaciones instaladas"
}

install_fonts_themes() {
    print_step "Instalando fuentes y temas"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm \
    nerd-fonts-cascadia-code \
    nerd-fonts-jetbrains-mono \
    nerd-fonts-fira-code \
    nerd-fonts-hack \
    nerd-fonts-source-code-pro \
    nerd-fonts-ubuntu-mono \
    nerd-fonts-inconsolata \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    ttf-font-awesome \
    ttf-fira-sans \
    ttf-fira-code \
    ttf-firacode-nerd \
    ttf-roboto \
    ttf-opensans \
    ttf-dejavu \
    ttf-liberation \
    adobe-source-code-pro-fonts \
    adobe-source-sans-fonts \
    adobe-source-serif-fonts \
    kvantum \
    qt5ct \
    qt6ct \
    nwg-look \
    papirus-icon-theme \
    catppuccin-gtk-theme-mocha \
    catppuccin-gtk-theme-macchiato \
    catppuccin-gtk-theme-frappe \
    catppuccin-gtk-theme-latte \
    arc-gtk-theme \
    materia-gtk-theme \
    nordic-theme \
    sweet-theme-git \
    orchis-theme-git \
    whitesur-gtk-theme \
    tela-icon-theme \
    beautyline-icons \
    flatery-icon-theme \
    reversal-icon-theme

EOF

    print_status "Fuentes y temas instalados"
}

install_pyprland() {
    print_step "Instalando pyprland"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm python-pyprland

EOF

    print_status "Pyprland instalado"
}

install_clipboard_tools() {
    print_step "Instalando herramientas de portapapeles"
    
    arch-chroot /mnt /bin/bash << 'EOF'
sudo -u $USER_NAME yay -S --noconfirm \
    wl-clipboard \
    cliphist

EOF

    print_status "Herramientas de portapapeles instaladas"
}

# =============================================================================
# CONFIGURACIÓN DE DOTFILES
# =============================================================================

install_dotfiles() {
    print_step "Instalando dotfiles y configuraciones mejoradas"
    
    arch-chroot /mnt /bin/bash << EOF
# Crear directorios necesarios
sudo -u $USER_NAME mkdir -p /home/$USER_NAME/{.config,.local/bin,Scripts,Downloads,Documents,Pictures/wallpapers,.themes,.icons}

# Copiar configuraciones desde el script
cd /tmp
git clone https://github.com/usuario/dothyprland.git dotfiles || true

if [ -d dotfiles ]; then
    # Copiar configuraciones
    sudo -u $USER_NAME cp -r dotfiles/.config/* /home/$USER_NAME/.config/
    sudo -u $USER_NAME cp -r dotfiles/Scripts/* /home/$USER_NAME/Scripts/
    sudo -u $USER_NAME cp dotfiles/.zshenv /home/$USER_NAME/
    sudo -u $USER_NAME cp dotfiles/.tmux.conf /home/$USER_NAME/
    
    # Hacer ejecutables los scripts
    chmod +x /home/$USER_NAME/Scripts/*
    
    # Cambiar permisos
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
fi

# Crear configuraciones mejoradas de Hyprland
sudo -u $USER_NAME mkdir -p /home/$USER_NAME/.config/hypr/scripts
sudo -u $USER_NAME mkdir -p /home/$USER_NAME/.config/hypr/themes

# Configuración avanzada de Hyprland
cat > /home/$USER_NAME/.config/hypr/hyprland.conf << 'HYPR_EOF'
# =============================================================================
# HYPRLAND CONFIGURATION - OPTIMIZADA Y MEJORADA
# =============================================================================

# Monitores
monitor=,preferred,auto,1

# Programas por defecto
\$terminal = kitty
\$fileManager = ranger
\$browser = google-chrome-stable
\$notes = obsidian
\$mail = neomutt
\$editor = code
\$editor-alt = subl
\$colorPicker = hyprpicker

# Ejecutar al inicio
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = swww-daemon
exec-once = swww img ~/.wallpapers/default.jpg --transition-fps 255 --transition-type outer --transition-duration 0.8
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle
exec-once = mako
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = pypr
exec-once = waybar

# Variables de entorno mejoradas
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_STYLE_OVERRIDE,kvantum
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = _JAVA_AWT_WM_NONREPARENTING,1
env = ELECTRON_OZONE_PLATFORM_HINT,wayland

# Configuración general mejorada
general { 
    gaps_in = 8
    gaps_out = 16
    border_size = 3
    col.active_border = rgb(8aadf4) rgb(24273A) rgb(24273A) rgb(8aadf4) 45deg
    col.inactive_border = rgb(24273A) rgb(24273A) rgb(24273A) rgb(27273A) 45deg
    resize_on_border = true
    allow_tearing = false
    layout = dwindle
}

# Decoraciones mejoradas
decoration {
    rounding = 12
    active_opacity = 0.98
    inactive_opacity = 0.90
    drop_shadow = true
    shadow_range = 10
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    
    blur {
        enabled = true
        size = 5
        passes = 3
        new_optimizations = true
        vibrancy = 0.1696
        ignore_opacity = true
        popups = true
        popups_ignorealpha = 0.2
    }
}

# Animaciones mejoradas
animations {
    enabled = true
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = liner, 1, 1, 1, 1
    bezier = overshot, 0.05, 0.9, 0.1, 1.1
    
    animation = windows, 1, 8, wind, slide
    animation = windowsIn, 1, 8, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 1, liner
    animation = borderangle, 1, 30, liner, loop
    animation = fade, 1, 10, default
    animation = workspaces, 1, 6, overshot
    animation = specialWorkspace, 1, 6, overshot, slidevert
}

# Configuración de entrada mejorada
input {
    kb_layout = es
    kb_variant =
    kb_model =
    kb_options = grp:alt_shift_toggle
    kb_rules =
    follow_mouse = 1
    sensitivity = 0
    force_no_accel = false
    
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
        drag_lock = true
    }
}

# Gestos
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 30
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_create_new = true
}

# Configuración misc mejorada
misc { 
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    vrr = 1
    enable_swallow = true
    swallow_regex = ^(kitty)$
    focus_on_activate = true
    animate_manual_resizes = true
    animate_mouse_windowdragging = true
    new_window_takes_over_fullscreen = 2
}

# Configuración de dwindle mejorada
dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = true
    smart_resizing = true
    force_split = 0
    split_width_multiplier = 1.0
    no_gaps_when_only = false
    use_active_for_splits = true
}

# Master layout
master {
    new_is_master = true
    new_on_top = false
    no_gaps_when_only = false
    orientation = left
    inherit_fullscreen = true
    always_center_master = false
    smart_resizing = true
    drop_at_cursor = true
}

# Keybindings mejorados
\$mainMod = SUPER

# Aplicaciones principales
bind = \$mainMod, RETURN, exec, \$terminal
bind = \$mainMod ALT, RETURN, exec, \$terminal --start-as=fullscreen
bind = \$mainMod SHIFT, RETURN, exec, \$terminal --class=floating-terminal
bind = \$mainMod, D, exec, wofi --show drun
bind = \$mainMod, B, exec, \$browser
bind = \$mainMod, O, exec, \$notes
bind = \$mainMod, C, exec, \$editor
bind = \$mainMod, S, exec, \$editor-alt
bind = \$mainMod, E, exec, \$terminal -e neomutt

# Control de ventanas
bind = \$mainMod, Q, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, V, togglefloating,
bind = \$mainMod, P, pseudo,
bind = \$mainMod, J, togglesplit,
bind = \$mainMod, F, fullscreen, 0
bind = \$mainMod SHIFT, F, fullscreen, 1

# Movimiento y focus
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

bind = \$mainMod, h, movefocus, l
bind = \$mainMod, l, movefocus, r
bind = \$mainMod, k, movefocus, u
bind = \$mainMod, j, movefocus, d

# Mover ventanas
bind = \$mainMod SHIFT, left, movewindow, l
bind = \$mainMod SHIFT, right, movewindow, r
bind = \$mainMod SHIFT, up, movewindow, u
bind = \$mainMod SHIFT, down, movewindow, d

bind = \$mainMod SHIFT, h, movewindow, l
bind = \$mainMod SHIFT, l, movewindow, r
bind = \$mainMod SHIFT, k, movewindow, u
bind = \$mainMod SHIFT, j, movewindow, d

# Redimensionar ventanas
bind = \$mainMod CTRL, left, resizeactive, -20 0
bind = \$mainMod CTRL, right, resizeactive, 20 0
bind = \$mainMod CTRL, up, resizeactive, 0 -20
bind = \$mainMod CTRL, down, resizeactive, 0 20

# Workspaces
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

# Mover a workspace
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

# Special workspaces
bind = \$mainMod, grave, togglespecialworkspace, magic
bind = \$mainMod SHIFT, grave, movetoworkspace, special:magic

# Scroll workspaces
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Mouse bindings
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Herramientas del sistema
bind = ALT, V, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy
bind = \$mainMod, PRINT, exec, grimblast --notify copysave area
bind = SHIFT, PRINT, exec, grimblast --notify copysave active
bind = , PRINT, exec, grimblast --notify copysave screen
bind = \$mainMod, L, exec, hyprlock
bind = \$mainMod, ESCAPE, exec, wlogout
bind = CTRL, ESCAPE, exec, killall waybar || waybar

# Pyprland scratchpads
bind = \$mainMod, F1, exec, pypr toggle term
bind = \$mainMod, F2, exec, pypr toggle ranger
bind = \$mainMod, F3, exec, pypr toggle volume
bind = \$mainMod, F4, exec, pypr toggle network
bind = \$mainMod SHIFT, G, exec, pypr toggle lazygit
bind = \$mainMod SHIFT, D, exec, pypr toggle lazydocker

# Media keys
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
bind = , XF86MonBrightnessUp, exec, brightnessctl s +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl s 5%-

# Reglas de ventana mejoradas
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(file_progress)$
windowrule = float, ^(confirm)$
windowrule = float, ^(dialog)$
windowrule = float, ^(download)$
windowrule = float, ^(notification)$
windowrule = float, ^(error)$
windowrule = float, ^(splash)$
windowrule = float, ^(confirmreset)$
windowrule = float, title:Open File
windowrule = float, title:branchdialog
windowrule = float, ^(Lxappearance)$
windowrule = float, ^(Rofi)$
windowrule = float, ^(eog)$
windowrule = float, ^(mpv)$

# Reglas v2 mejoradas
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$
windowrulev2 = opacity 0.85 0.85,class:^(org.gnome.Nautilus)$
windowrulev2 = opacity 0.90 0.90,class:^(obsidian)$
windowrulev2 = opacity 0.80 0.80,class:^(pavucontrol)$
windowrulev2 = opacity 0.70 0.70,class:^(Spotify)$
windowrulev2 = opacity 0.95 0.95,class:^(firefox)$
windowrulev2 = opacity 0.95 0.95,class:^(google-chrome)$

windowrulev2 = float,class:^(floating-terminal)$
windowrulev2 = size 800 600,class:^(floating-terminal)$
windowrulev2 = center,class:^(floating-terminal)$

# Layer rules
layerrule = blur,waybar
layerrule = ignorezero,waybar
layerrule = blur,wofi
layerrule = ignorezero,wofi
layerrule = blur,mako
layerrule = ignorezero,mako

# Plugin configuration
plugin {
    hyprfocus {
        enabled = yes
        animate_floating = yes
        animate_workspacechange = yes
        focus_animation = shrink
        bezier = bezIn, 0.5,0.0,1.0,0.5
        bezier = bezOut, 0.0,0.5,0.5,1.0
        flash {
            flash_opacity = 0.7
            in_bezier = bezIn
            in_speed = 0.5
            out_bezier = bezOut
            out_speed = 3
        }
        shrink {
            shrink_percentage = 0.8
            in_bezier = bezIn
            in_speed = 0.5
            out_bezier = bezOut
            out_speed = 3
        }
    }
}
HYPR_EOF

chown $USER_NAME:$USER_NAME /home/$USER_NAME/.config/hypr/hyprland.conf

EOF

    print_status "Dotfiles y configuraciones mejoradas instaladas"
}

configure_shell() {
    print_step "Configurando shell con fnm y pyenv"
    
    arch-chroot /mnt /bin/bash << EOF
# Cambiar shell por defecto a zsh
chsh -s /bin/zsh $USER_NAME

# Instalar Oh My Zsh
sudo -u $USER_NAME sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Instalar plugins adicionales
sudo -u $USER_NAME git clone https://github.com/zsh-users/zsh-autosuggestions /home/$USER_NAME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sudo -u $USER_NAME git clone https://github.com/zsh-users/zsh-syntax-highlighting /home/$USER_NAME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Configurar .zshrc con fnm y pyenv
cat > /home/$USER_NAME/.zshrc << 'ZSHRC_EOF'
# Oh My Zsh configuration
export ZSH="/home/$USER_NAME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    docker-compose
    python
    rust
    golang
)

source \$ZSH/oh-my-zsh.sh

# User configuration
export LANG=es_ES.UTF-8
export EDITOR='nvim'

# fnm (Fast Node Manager)
export PATH="/home/$USER_NAME/.local/share/fnm:\$PATH"
eval "\$(fnm env --use-on-cd)"

# pyenv
export PYENV_ROOT="/home/$USER_NAME/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"

# Rust
export PATH="/home/$USER_NAME/.cargo/bin:\$PATH"

# Go
export GOPATH="/home/$USER_NAME/go"
export PATH="\$GOPATH/bin:\$PATH"

# Local binaries
export PATH="/home/$USER_NAME/.local/bin:\$PATH"
export PATH="/home/$USER_NAME/Scripts:\$PATH"

# Aliases personalizados
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vim='nvim'
alias cat='bat'
alias ls='exa'
alias ll='exa -la'
alias tree='exa --tree'
alias df='duf'
alias du='dust'
alias ps='procs'
alias top='btop'
alias htop='btop'
alias ping='gping'
alias dig='dog'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'

# Sistema
alias actualizar='sudo pacman -Syu && yay -Syu'
alias limpiar='yay -Sc && sudo pacman -Rns \$(pacman -Qtdq) 2>/dev/null || true'
alias buscar='yay -Ss'
alias instalar='yay -S'
alias desinstalar='yay -R'

# Funciones útiles
mkcd() {
    mkdir -p "\$1" && cd "\$1"
}

extract() {
    if [ -f "\$1" ]; then
        case "\$1" in
            *.tar.bz2)   tar xjf "\$1"     ;;
            *.tar.gz)    tar xzf "\$1"     ;;
            *.bz2)       bunzip2 "\$1"    ;;
            *.rar)       unrar x "\$1"    ;;
            *.gz)        gunzip "\$1"     ;;
            *.tar)       tar xf "\$1"     ;;
            *.tbz2)      tar xjf "\$1"    ;;
            *.tgz)       tar xzf "\$1"    ;;
            *.zip)       unzip "\$1"      ;;
            *.Z)         uncompress "\$1" ;;
            *.7z)        7z x "\$1"       ;;
            *)           echo "No sé cómo extraer '\$1'..." ;;
        esac
    else
        echo "'\$1' no es un archivo válido!"
    fi
}

# Starship prompt (si está instalado)
if command -v starship &> /dev/null; then
    eval "\$(starship init zsh)"
fi

# Source additional configs
[ -f ~/.config/zsh/aliases.zsh ] && source ~/.config/zsh/aliases.zsh
[ -f ~/.config/zsh/exports.zsh ] && source ~/.config/zsh/exports.zsh
ZSHRC_EOF

chown $USER_NAME:$USER_NAME /home/$USER_NAME/.zshrc

# Crear configuración adicional de zsh
sudo -u $USER_NAME mkdir -p /home/$USER_NAME/.config/zsh

# Configurar fnm y pyenv paths
cat > /home/$USER_NAME/.zshenv << 'ZSHENV_EOF'
# XDG Base Directory
export XDG_CONFIG_HOME="\$HOME/.config"
export XDG_CACHE_HOME="\$HOME/.cache"
export XDG_DATA_HOME="\$HOME/.local/share"

# Zsh config directory
export ZDOTDIR="\$HOME/.config/zsh"

# fnm
export PATH="\$HOME/.local/share/fnm:\$PATH"

# pyenv
export PYENV_ROOT="\$HOME/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"
ZSHENV_EOF

chown $USER_NAME:$USER_NAME /home/$USER_NAME/.zshenv

EOF

    print_status "Shell configurado con fnm y pyenv"
}

configure_services() {
    print_step "Configurando servicios del sistema"
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Habilitar servicios esenciales
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable systemd-timesyncd

# Configurar greetd (display manager)
if command -v greetd &> /dev/null; then
    systemctl enable greetd
    
    cat > /etc/greetd/config.toml << EOL
[terminal]
vt = 1

[default_session]
command = "Hyprland"
user = "$USER_NAME"

[initial_session]
command = "Hyprland"
user = "$USER_NAME"
EOL
fi

EOF

    print_status "Servicios configurados"
}

# =============================================================================
# CORRECCIÓN DE ERRORES EN CONFIGURACIÓN
# =============================================================================

fix_config_errors() {
    print_step "Creando configuraciones mejoradas y corrigiendo errores"
    
    arch-chroot /mnt /bin/bash << EOF
# Configuración mejorada de Mako
cat > /home/$USER_NAME/.config/mako/config << 'MAKO_EOF'
# GLOBAL
max-history=100
sort=-time

# BINDING OPTIONS
on-button-left=dismiss
on-button-middle=none
on-button-right=dismiss-all
on-touch=dismiss

# STYLE OPTIONS
font=CaskaydiaCove Nerd Font Mono 12
width=400
height=200
margin=20
padding=20
border-size=3
border-radius=12
icons=1
max-icon-size=48
markup=1
actions=1
history=1
text-alignment=left
default-timeout=5000
ignore-timeout=0
max-visible=5
layer=overlay
anchor=top-right

# COLORS - Catppuccin Mocha
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
progress-color=over #89b4fa

[urgency=low]
border-color=#313244
default-timeout=2000

[urgency=normal]
border-color=#89b4fa
default-timeout=5000

[urgency=high]
border-color=#f38ba8
text-color=#f38ba8
default-timeout=0

[category=mpd]
default-timeout=2000
group-by=category
MAKO_EOF

# Configuración mejorada de Wofi
cat > /home/$USER_NAME/.config/wofi/config << 'WOFI_EOF'
## Wofi Config Mejorada

## General
show=drun
prompt=Aplicaciones
normal_window=true
layer=top
term=kitty
columns=2
mode=drun

## Geometry
width=800px
height=600px
location=0
orientation=vertical
halign=fill
line_wrap=off
dynamic_lines=false

## Images
allow_markup=true
allow_images=true
image_size=32

## Search
exec_search=false
hide_search=false
parse_search=false
insensitive=true

## Other
hide_scroll=true
no_actions=true
sort_order=alphabetical
gtk_dark=true
filter_rate=100
matching=fuzzy

## Keys
key_expand=Tab
key_exit=Escape
key_up=Up
key_down=Down
key_left=Left
key_right=Right
key_forward=Control_L-n
key_backward=Control_L-p
WOFI_EOF

# Configuración mejorada de Kitty
cat > /home/$USER_NAME/.config/kitty/kitty.conf << 'KITTY_EOF'
# Fuentes
font_family      CaskaydiaCove Nerd Font Mono
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size 12.0

# Cursor
cursor_shape block
cursor_beam_thickness 2
cursor_underline_thickness 2.0
cursor_blink_interval 0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
wheel_scroll_multiplier 5.0

# Mouse
mouse_hide_wait 3.0
url_color #0087bd
url_style curly
copy_on_select yes
click_interval -1.0
focus_follows_mouse no

# Performance
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Window
window_padding_width 20
placement_strategy center
hide_window_decorations no
confirm_os_window_close 1

# Tabs
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template "{title}"

# Advanced
shell zsh
editor nvim
close_on_child_death no
allow_remote_control yes
update_check_interval 0

# Keyboard shortcuts
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+t new_tab
map ctrl+shift+w close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
map ctrl+shift+enter new_window
map ctrl+shift+n new_os_window
map ctrl+shift+f show_scrollback

# Tema
include theme.conf
KITTY_EOF

# Tema para Kitty - Catppuccin Mocha
cat > /home/$USER_NAME/.config/kitty/theme.conf << 'THEME_EOF'
# The basic colors
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC

# Cursor colors
cursor                  #F5E0DC
cursor_text_color       #1E1E2E

# URL underline color when hovering with mouse
url_color               #F5E0DC

# Kitty window border colors
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF

# Tab bar colors
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# Colors for marks (marked text in the terminal)
mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC

# The 16 terminal colors

# black
color0 #45475A
color8 #585B70

# red
color1 #F38BA8
color9 #F38BA8

# green
color2  #A6E3A1
color10 #A6E3A1

# yellow
color3  #F9E2AF
color11 #F9E2AF

# blue
color4  #89B4FA
color12 #89B4FA

# magenta
color5  #F5C2E7
color13 #F5C2E7

# cyan
color6  #94E2D5
color14 #94E2D5

# white
color7  #BAC2DE
color15 #A6ADC8
THEME_EOF

# Configuración mejorada de Pyprland
cat > /home/$USER_NAME/.config/hypr/pyprland.toml << 'PYPR_EOF'
[pyprland]
plugins = [
    "expose",
    "fetch_client_menu", 
    "lost_windows",
    "magnify",
    "scratchpads",
    "shift_monitors",
    "toggle_special",
    "workspaces_follow_focus",
]

[pyprland.variables]
term_classed = "kitty --class"

[scratchpads.term]
animation = "fromTop"
command = "kitty --class kitty-dropterm --title 'Scratchpad Terminal'"
class = "kitty-dropterm"
size = "70% 65%"
max_size = "1920px 1080px"
margin = 100
lazy = true

[scratchpads.volume]
animation = "fromRight"
command = "pavucontrol"
class = "org.pulseaudio.pavucontrol"
size = "45% 90%"
unfocus = "hide"
lazy = true

[scratchpads.network]
animation = "fromRight"  
command = "nm-connection-editor"
class = "nm-connection-editor"
size = "45% 70%"
unfocus = "hide"
lazy = true

[scratchpads.ranger]
animation = "fromLeft"
command = "kitty --class kitty-ranger --title 'File Manager' -e ranger"
class = "kitty-ranger"
size = "70% 75%"
max_size = "1920px 1080px"
lazy = true

[scratchpads.lazygit]
animation = "fromBottom"
command = "kitty --class kitty-lazygit --title 'LazyGit' -e lazygit"
class = "kitty-lazygit"
size = "85% 85%"
max_size = "1920px 1080px"
lazy = true

[scratchpads.lazydocker]
animation = "fromBottom"
command = "kitty --class kitty-lazydocker --title 'LazyDocker' -e lazydocker"
class = "kitty-lazydocker"
size = "85% 85%"
max_size = "1920px 1080px"
lazy = true

[scratchpads.music]
animation = "fromLeft"
command = "kitty --class kitty-music --title 'Music Player' -e ncmpcpp"
class = "kitty-music"
size = "70% 70%"
unfocus = "hide"
lazy = true

[scratchpads.calculator]
animation = "fromTop"
command = "qalculate-gtk"
class = "qalculate-gtk"
size = "400px 600px"
unfocus = "hide"
lazy = true
PYPR_EOF

# Asegurar que las dependencias de scripts están instaladas
sudo -u $USER_NAME yay -S --noconfirm --needed \
    jq \
    socat \
    imagemagick \
    libnotify \
    brightnessctl \
    upower \
    acpi \
    bc \
    dust \
    procs \
    gping \
    dog \
    qalculate-gtk

# Crear directorio de wallpapers con wallpaper por defecto
sudo -u $USER_NAME mkdir -p /home/$USER_NAME/.wallpapers

# Crear wallpaper por defecto si ImageMagick está disponible
if command -v convert &> /dev/null; then
    convert -size 1920x1080 gradient:'#1e1e2e'-'#313244' /home/$USER_NAME/.wallpapers/default.jpg
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.wallpapers/default.jpg
fi

# Cambiar permisos finales
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

EOF

    print_status "Configuraciones mejoradas creadas y errores corregidos"
}

# =============================================================================
# MENÚ PRINCIPAL
# =============================================================================

show_module_menu() {
    while true; do
        clear
        print_logo
        echo -e "${CYAN}SELECCIÓN DE MÓDULOS PARA INSTALAR${NC}"
        echo -e "${WHITE}======================================${NC}"
        echo
        echo -e "${GREEN}1.${NC}  Hyprland Base (Compositor y básicos)"
        echo -e "${GREEN}2.${NC}  Herramientas de Terminal"
        echo -e "${GREEN}3.${NC}  Herramientas Multimedia"
        echo -e "${GREEN}4.${NC}  Herramientas de Desarrollo"
        echo -e "${GREEN}5.${NC}  Aplicaciones"
        echo -e "${GREEN}6.${NC}  Fuentes y Temas"
        echo -e "${GREEN}7.${NC}  Pyprland (Scratchpads)"
        echo -e "${GREEN}8.${NC}  Herramientas de Portapapeles"
        echo -e "${GREEN}9.${NC}  Dotfiles y Configuración"
        echo -e "${GREEN}10.${NC} Configurar Shell"
        echo -e "${GREEN}11.${NC} Todos los módulos"
        echo -e "${GREEN}0.${NC}  Continuar con la instalación"
        echo
        
        read -p "$(echo -e "${CYAN}Selecciona los módulos (separados por espacios): ${NC}")" modules
        
        case "$modules" in
            *"1"*|*"11"*) 
                install_hyprland_base
                ;;
        esac
        
        case "$modules" in
            *"2"*|*"11"*) 
                install_terminal_tools
                ;;
        esac
        
        case "$modules" in
            *"3"*|*"11"*) 
                install_multimedia_tools
                ;;
        esac
        
        case "$modules" in
            *"4"*|*"11"*) 
                install_development_tools
                ;;
        esac
        
        case "$modules" in
            *"5"*|*"11"*) 
                install_applications
                ;;
        esac
        
        case "$modules" in
            *"6"*|*"11"*) 
                install_fonts_themes
                ;;
        esac
        
        case "$modules" in
            *"7"*|*"11"*) 
                install_pyprland
                ;;
        esac
        
        case "$modules" in
            *"8"*|*"11"*) 
                install_clipboard_tools
                ;;
        esac
        
        case "$modules" in
            *"9"*|*"11"*) 
                install_dotfiles
                ;;
        esac
        
        case "$modules" in
            *"10"*|*"11"*) 
                configure_shell
                ;;
        esac
        
        if [[ "$modules" == "0" ]] || [[ "$modules" == *"11"* ]]; then
            break
        fi
        
        if ask_confirmation "¿Instalar más módulos?"; then
            continue
        else
            break
        fi
    done
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    print_logo
    
    if ! ask_confirmation "¿Continuar con la instalación de Arch Linux + Hyprland?"; then
        exit 0
    fi
    
    # Verificaciones iniciales
    check_internet
    check_uefi
    
    # Configuración del usuario
    get_user_input
    select_disk
    
    # Instalación base
    partition_disk
    install_base_system
    configure_base_system
    install_bootloader
    
    # Instalación modular
    show_module_menu
    
    # Configuraciones finales
    configure_services
    fix_config_errors
    
    print_step "¡INSTALACIÓN COMPLETADA!"
    print_status "El sistema está listo para usar"
    print_status "Log de instalación guardado en: $LOG_FILE"
    
    echo -e "\n${GREEN}Recomendaciones post-instalación:${NC}"
    echo -e "${YELLOW}1.${NC} Reinicia el sistema"
    echo -e "${YELLOW}2.${NC} Inicia sesión con tu usuario"
    echo -e "${YELLOW}3.${NC} Ejecuta Hyprland"
    echo -e "${YELLOW}4.${NC} Configura tus wallpapers en ~/.wallpapers/"
    echo -e "${YELLOW}5.${NC} Personaliza la configuración según tus necesidades"
    
    if ask_confirmation "¿Reiniciar ahora?"; then
        umount -R /mnt
        reboot
    fi
}

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root"
    exit 1
fi

# Ejecutar función principal
main "$@"
