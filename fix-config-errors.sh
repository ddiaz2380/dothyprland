#!/bin/bash

# =============================================================================
# CORRECTOR DE CONFIGURACIONES Y ERRORES
# Script para corregir errores comunes en dotfiles de Hyprland
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${PURPLE}==> $1${NC}"
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Backup creado: ${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# =============================================================================
# CORRECCIONES DE HYPRLAND
# =============================================================================

fix_hyprland_config() {
    print_step "Corrigiendo configuración de Hyprland"
    
    local config_file="$HOME/.config/hypr/hyprland.conf"
    
    if [ ! -f "$config_file" ]; then
        print_error "Archivo de configuración de Hyprland no encontrado"
        return 1
    fi
    
    backup_file "$config_file"
    
    # Corregir duplicados de workspace bindings
    print_status "Eliminando bindings duplicados de workspace"
    sed -i '/^bind = \$mainMod, [0-9], exec, hyprctl dispatch workspace [0-9]/d' "$config_file"
    
    # Corregir variables de entorno duplicadas
    print_status "Corrigiendo variables de entorno duplicadas"
    sed -i '/^env = XCURSOR_SIZE,24$/d' "$config_file"
    echo "env = XCURSOR_SIZE,24" >> "$config_file"
    
    # Corregir configuración de monitores
    print_status "Corrigiendo configuración de monitores"
    sed -i 's/monitor=,preferred,auto,1,mirror,DP-1/monitor=,preferred,auto,1/' "$config_file"
    
    # Añadir configuración de tearing si no existe
    if ! grep -q "allow_tearing" "$config_file"; then
        print_status "Añadiendo configuración de tearing"
        sed -i '/allow_tearing = false/a\\n    # Para aplicaciones que requieren tearing\n    # allow_tearing = true' "$config_file"
    fi
    
    print_status "Configuración de Hyprland corregida"
}

fix_mako_config() {
    print_step "Corrigiendo configuración de Mako"
    
    local config_file="$HOME/.config/mako/config"
    
    if [ ! -f "$config_file" ]; then
        print_warning "Archivo de configuración de Mako no encontrado, creando uno nuevo"
        mkdir -p "$HOME/.config/mako"
        
        tee "$config_file" > /dev/null << 'EOF'
# GLOBAL
max-history=100
sort=-time

# BINDING OPTIONS
on-button-left=dismiss
on-button-middle=none
on-button-right=dismiss-all
on-touch=dismiss

# STYLE OPTIONS
font=CaskaydiaCove Nerd Font Mono 14
width=500
height=300
margin=10
padding=15
border-size=4
border-radius=12
icons=1
max-icon-size=58
markup=1
actions=1
history=1
text-alignment=center
default-timeout=4000
ignore-timeout=0
max-visible=10
layer=overlay
anchor=top-center

background-color=#1e1e2e
text-color=#cdd6f4
border-color=#cba6f7
progress-color=over #89b4fa

[urgency=low]
border-color=#313244
default-timeout=2000

[urgency=normal]
border-color=#cba6f7
default-timeout=5000

[urgency=high]
border-color=#f38ba8
text-color=#f38ba8
default-timeout=0
EOF
        return 0
    fi
    
    backup_file "$config_file"
    
    # Comentar icon-location si existe (causa errores en algunas versiones)
    if grep -q "^icon-location=" "$config_file"; then
        print_status "Comentando icon-location problemático"
        sed -i 's/^icon-location=/#icon-location=/' "$config_file"
    fi
    
    # Corregir configuración de anchors
    if grep -q "anchor=top-center" "$config_file"; then
        print_status "Configuración de anchor verificada"
    else
        print_status "Añadiendo configuración de anchor"
        sed -i '/layer=overlay/a anchor=top-center' "$config_file"
    fi
    
    print_status "Configuración de Mako corregida"
}

fix_wofi_config() {
    print_step "Corrigiendo configuración de Wofi"
    
    local config_file="$HOME/.config/wofi/config"
    
    if [ ! -f "$config_file" ]; then
        print_warning "Archivo de configuración de Wofi no encontrado"
        return 1
    fi
    
    backup_file "$config_file"
    
    # Corregir terminal command
    if grep -q "term=wezterm" "$config_file"; then
        print_status "Cambiando terminal de wezterm a kitty"
        sed -i 's/term=wezterm/term=kitty/' "$config_file"
    fi
    
    # Verificar configuración de imágenes
    if ! grep -q "image_size=" "$config_file"; then
        print_status "Añadiendo configuración de tamaño de imagen"
        echo "image_size=24" >> "$config_file"
    fi
    
    print_status "Configuración de Wofi corregida"
}

fix_kitty_config() {
    print_step "Corrigiendo configuración de Kitty"
    
    local config_file="$HOME/.config/kitty/kitty.conf"
    
    if [ ! -f "$config_file" ]; then
        print_warning "Archivo de configuración de Kitty no encontrado"
        return 1
    fi
    
    backup_file "$config_file"
    
    # Verificar que la fuente existe
    if fc-list | grep -q "CaskaydiaCove Nerd Font"; then
        print_status "Fuente CaskaydiaCove Nerd Font encontrada"
    else
        print_warning "Fuente CaskaydiaCove no encontrada, cambiando a JetBrains Mono"
        sed -i 's/font_family      CaskaydiaCove Nerd Font Mono/font_family      JetBrains Mono Nerd Font/' "$config_file"
    fi
    
    # Añadir configuraciones faltantes si no existen
    if ! grep -q "cursor_shape" "$config_file"; then
        print_status "Añadiendo configuraciones adicionales de cursor"
        echo "" >> "$config_file"
        echo "# Cursor configuration" >> "$config_file"
        echo "cursor_shape block" >> "$config_file"
        echo "cursor_blink_interval 0" >> "$config_file"
    fi
    
    print_status "Configuración de Kitty corregida"
}

fix_pyprland_config() {
    print_step "Corrigiendo configuración de Pyprland"
    
    local config_file="$HOME/.config/hypr/pyprland.toml"
    
    if [ ! -f "$config_file" ]; then
        print_warning "Archivo de configuración de Pyprland no encontrado"
        return 1
    fi
    
    backup_file "$config_file"
    
    # Verificar que spotify command existe
    if ! command -v spotify &> /dev/null; then
        print_status "Corrigiendo comando de Spotify en pyprland"
        sed -i 's/command = "kitty --class kitty-spotify -e spotify"/command = "kitty --class kitty-spotify -e ncspot"/' "$config_file"
    fi
    
    # Verificar configuración de clases de ventana
    local classes=("kitty-dropterm" "kitty-ranger" "kitty-lazygit" "kitty-lazydocker" "kitty-spotify" "kitty-neomutt")
    
    for class in "${classes[@]}"; do
        if ! grep -q "class = \"$class\"" "$config_file"; then
            print_warning "Clase $class no encontrada en configuración"
        fi
    done
    
    print_status "Configuración de Pyprland verificada"
}

# =============================================================================
# CORRECCIONES DE SCRIPTS
# =============================================================================

fix_scripts_permissions() {
    print_step "Corrigiendo permisos de scripts"
    
    local scripts_dir="$HOME/Scripts"
    
    if [ ! -d "$scripts_dir" ]; then
        print_warning "Directorio Scripts no encontrado"
        mkdir -p "$scripts_dir"
        return 1
    fi
    
    # Hacer ejecutables todos los scripts
    find "$scripts_dir" -type f -exec chmod +x {} \;
    
    print_status "Permisos de scripts corregidos"
}

fix_volume_script() {
    print_step "Corrigiendo script de volumen"
    
    local script_file="$HOME/Scripts/volume"
    
    if [ ! -f "$script_file" ]; then
        print_warning "Script de volumen no encontrado"
        return 1
    fi
    
    backup_file "$script_file"
    
    # Verificar que pamixer está instalado
    if ! command -v pamixer &> /dev/null; then
        print_warning "pamixer no está instalado, instalando..."
        yay -S --noconfirm pamixer
    fi
    
    # Crear directorio de iconos si no existe
    local icons_dir="$HOME/.config/mako/icons"
    if [ ! -d "$icons_dir" ]; then
        print_status "Creando directorio de iconos para mako"
        mkdir -p "$icons_dir"
        
        # Descargar iconos básicos o usar iconos del sistema
        if command -v find &> /dev/null; then
            # Buscar iconos de volumen en el sistema
            local system_icons=$(find /usr/share/icons -name "*volume*" -type f 2>/dev/null | head -4)
            
            if [ -n "$system_icons" ]; then
                echo "$system_icons" | while IFS= read -r icon; do
                    cp "$icon" "$icons_dir/" 2>/dev/null || true
                done
            fi
        fi
    fi
    
    print_status "Script de volumen verificado"
}

fix_wallpaper_scripts() {
    print_step "Corrigiendo scripts de wallpaper"
    
    # Crear directorio de wallpapers si no existe
    local wallpaper_dir="$HOME/.wallpapers"
    if [ ! -d "$wallpaper_dir" ]; then
        print_status "Creando directorio de wallpapers"
        mkdir -p "$wallpaper_dir"
        
        # Crear wallpaper por defecto si no hay ninguno
        if command -v convert &> /dev/null; then
            print_status "Creando wallpaper por defecto"
            convert -size 1920x1080 gradient:'#1e1e2e'-'#313244' "$wallpaper_dir/default.png"
        fi
    fi
    
    # Verificar que swww está instalado
    if ! command -v swww &> /dev/null; then
        print_warning "swww no está instalado, instalando..."
        yay -S --noconfirm swww
    fi
    
    print_status "Scripts de wallpaper verificados"
}

# =============================================================================
# CORRECCIONES DE DEPENDENCIAS
# =============================================================================

install_missing_dependencies() {
    print_step "Verificando e instalando dependencias faltantes"
    
    local dependencies=(
        "kitty"
        "wofi" 
        "mako"
        "swww"
        "hyprlock"
        "hypridle"
        "hyprpicker"
        "wlogout"
        "pamixer"
        "playerctl"
        "cliphist"
        "wl-clipboard"
        "grim"
        "slurp"
        "jq"
        "socat"
        "libnotify"
        "brightnessctl"
        "ranger"
        "btop"
        "fastfetch"
        "bat"
        "starship"
        "exa"
        "dust"
        "procs"
        "gping"
        "dog"
        "fnm-bin"
        "pyenv"
        "google-chrome"
        "visual-studio-code-bin"
        "qalculate-gtk"
    )
    
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! pacman -Qi "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_status "Instalando dependencias faltantes: ${missing_deps[*]}"
        yay -S --noconfirm "${missing_deps[@]}" || print_warning "Algunas dependencias no se pudieron instalar"
    else
        print_status "Todas las dependencias están instaladas"
    fi
    
    # Verificar configuración de fnm
    if command -v fnm &> /dev/null; then
        print_status "Verificando configuración de fnm"
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env --use-on-cd)"
        
        # Instalar Node.js si no está instalado
        if ! fnm list | grep -q "v20"; then
            print_status "Instalando Node.js 20 con fnm"
            fnm install 20
            fnm use 20
            fnm default 20
        fi
    fi
    
    # Verificar configuración de pyenv
    if command -v pyenv &> /dev/null; then
        print_status "Verificando configuración de pyenv"
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
        
        # Instalar Python si no está instalado
        if ! pyenv versions | grep -q "3.11.7"; then
            print_status "Instalando Python 3.11.7 con pyenv"
            pyenv install 3.11.7
            pyenv global 3.11.7
        fi
    fi
}

fix_font_dependencies() {
    print_step "Verificando fuentes"
    
    local fonts=(
        "nerd-fonts-cascadia-code"
        "nerd-fonts-jetbrains-mono"
        "nerd-fonts-fira-code"
        "ttf-font-awesome"
        "ttf-fira-sans"
        "ttf-fira-code"
        "noto-fonts-emoji"
    )
    
    for font in "${fonts[@]}"; do
        if ! pacman -Qi "$font" &> /dev/null; then
            print_status "Instalando fuente: $font"
            yay -S --noconfirm "$font" || print_warning "No se pudo instalar $font"
        fi
    done
    
    # Actualizar cache de fuentes
    fc-cache -fv
    
    print_status "Fuentes verificadas"
}

# =============================================================================
# CORRECCIONES DE SERVICIOS
# =============================================================================

fix_services() {
    print_step "Verificando y configurando servicios"
    
    # Verificar que los servicios necesarios estén habilitados
    local services=(
        "NetworkManager"
        "bluetooth"
        "systemd-timesyncd"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &> /dev/null; then
            print_status "Servicio $service está habilitado"
        else
            print_status "Habilitando servicio $service"
            sudo systemctl enable "$service"
        fi
    done
    
    # Verificar servicios de usuario
    local user_services=(
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
    )
    
    for service in "${user_services[@]}"; do
        if systemctl --user is-enabled "$service" &> /dev/null 2>&1; then
            print_status "Servicio de usuario $service está habilitado"
        else
            if systemctl --user list-unit-files | grep -q "$service"; then
                print_status "Habilitando servicio de usuario $service"
                systemctl --user enable "$service"
            fi
        fi
    done
    
    print_status "Servicios verificados"
}

fix_essential_packages() {
    print_step "Verificando paquetes esenciales"
    
    local essential_packages=(
        "ttf-font-awesome"
        "fastfetch"
        "ttf-fira-sans"
        "ttf-fira-code"
        "jq"
        "brightnessctl"
        "networkmanager"
    )
    
    local missing_packages=()
    
    for package in "${essential_packages[@]}"; do
        if ! pacman -Qi "$package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_status "Instalando paquetes esenciales faltantes: ${missing_packages[*]}"
        sudo pacman -S --noconfirm "${missing_packages[@]}" || {
            print_warning "Algunos paquetes no se pudieron instalar desde repositorios oficiales"
        }
    else
        print_status "Todos los paquetes esenciales están instalados"
    fi
    
    # Verificar servicios críticos
    if ! systemctl is-enabled NetworkManager &>/dev/null; then
        print_status "Habilitando NetworkManager"
        sudo systemctl enable NetworkManager
    fi
    
    if ! systemctl is-active NetworkManager &>/dev/null; then
        print_status "Iniciando NetworkManager"
        sudo systemctl start NetworkManager
    fi
}

setup_ranger_complete() {
    print_step "Configurando Ranger con todas sus dependencias"
    
    # Verificar si el script de configuración existe
    if [ ! -f "Scripts/ranger-setup" ]; then
        print_error "Script ranger-setup no encontrado"
        return 1
    fi
    
    # Hacer ejecutable el script
    chmod +x Scripts/ranger-setup
    
    # Ejecutar configuración completa de Ranger
    print_info "Ejecutando configuración completa de Ranger..."
    bash Scripts/ranger-setup
    
    # Verificar configuración de Hyprland para Ranger
    if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
        if ! grep -q "pypr toggle ranger" "$HOME/.config/hypr/hyprland.conf"; then
            print_warning "Agregando keybinding para Ranger en Hyprland..."
            echo "" >> "$HOME/.config/hypr/hyprland.conf"
            echo "# Ranger scratchpad" >> "$HOME/.config/hypr/hyprland.conf"
            echo "bind = \$mainMod, F2, exec, pypr toggle ranger" >> "$HOME/.config/hypr/hyprland.conf"
        fi
    fi
    
    print_success "Configuración completa de Ranger terminada"
}

complete_system_validation() {
    print_step "Ejecutando validación completa del sistema"
    
    # Verificar si el script de validación existe
    if [ ! -f "Scripts/complete-system-validation" ]; then
        print_error "Script complete-system-validation no encontrado"
        return 1
    fi
    
    # Hacer ejecutable el script
    chmod +x Scripts/complete-system-validation
    
    # Ejecutar validación completa
    print_info "Ejecutando validación completa del sistema..."
    bash Scripts/complete-system-validation
    
    print_success "Validación completa del sistema terminada"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

run_all_fixes() {
    print_step "Ejecutando todas las correcciones"
    
    fix_hyprland_config
    fix_mako_config
    fix_wofi_config
    fix_kitty_config
    fix_pyprland_config
    fix_scripts_permissions
    fix_volume_script
    fix_wallpaper_scripts
    install_missing_dependencies
    fix_font_dependencies
    fix_services
    fix_essential_packages
    setup_ranger_complete
    
    print_step "¡Todas las correcciones completadas!"
}

show_menu() {
    while true; do
        clear
        echo -e "${CYAN}CORRECTOR DE CONFIGURACIONES${NC}"
        echo -e "${WHITE}==============================${NC}"
        echo
        echo -e "${GREEN}1.${NC}  Corregir configuración de Hyprland"
        echo -e "${GREEN}2.${NC}  Corregir configuración de Mako"
        echo -e "${GREEN}3.${NC}  Corregir configuración de Wofi"
        echo -e "${GREEN}4.${NC}  Corregir configuración de Kitty"
        echo -e "${GREEN}5.${NC}  Corregir configuración de Pyprland"
        echo -e "${GREEN}6.${NC}  Corregir permisos de scripts"
        echo -e "${GREEN}7.${NC}  Corregir script de volumen"
        echo -e "${GREEN}8.${NC}  Corregir scripts de wallpaper"
        echo -e "${GREEN}9.${NC}  Instalar dependencias faltantes"
        echo -e "${GREEN}10.${NC} Verificar fuentes"
        echo -e "${GREEN}11.${NC} Verificar servicios"
        echo -e "${GREEN}12.${NC} Verificar paquetes esenciales"
        echo -e "${GREEN}13.${NC} Configurar Ranger completo"
        echo -e "${GREEN}14.${NC} Validación completa del sistema"
        echo -e "${GREEN}15.${NC} Ejecutar todas las correcciones"
        echo -e "${GREEN}0.${NC}  Salir"
        echo
        
        read -p "$(echo -e "${CYAN}Selecciona una opción: ${NC}")" choice
        
        case $choice in
            1) fix_hyprland_config ;;
            2) fix_mako_config ;;
            3) fix_wofi_config ;;
            4) fix_kitty_config ;;
            5) fix_pyprland_config ;;
            6) fix_scripts_permissions ;;
            7) fix_volume_script ;;
            8) fix_wallpaper_scripts ;;
            9) install_missing_dependencies ;;
            10) fix_font_dependencies ;;
            11) fix_services ;;
            12) fix_essential_packages ;;
            13) setup_ranger_complete ;;
            14) complete_system_validation ;;
            15) run_all_fixes ;;
            0) exit 0 ;;
            *) echo "Opción inválida" ;;
        esac
        
        read -p "Presiona Enter para continuar..."
    done
}

main() {
    echo -e "${CYAN}CORRECTOR DE CONFIGURACIONES HYPRLAND${NC}"
    echo -e "${WHITE}=====================================${NC}"
    echo
    echo "Este script corregirá errores comunes en la configuración"
    echo "y se asegurará de que todas las dependencias estén instaladas."
    echo
    
    show_menu
}

main "$@"
