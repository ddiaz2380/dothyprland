#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "\n${GREEN}[$1/${TOTAL_STEPS}] ${YELLOW}$2${NC}"
}

confirm_step() {
    echo -e "\n${YELLOW}¿Proceder con este paso? (s/N): ${NC}"
    read confirm
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        echo -e "${RED}Paso saltado por el usuario${NC}"
        return 1
    fi
    return 0
}

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Completado exitosamente${NC}"
    else
        echo -e "${RED}✗ Error en la ejecución${NC}"
        echo -e "${YELLOW}¿Deseas continuar de todas formas? (s/N): ${NC}"
        read continue
        if [[ $continue != "s" && $continue != "S" ]]; then
            echo -e "${RED}Instalación interrumpida por el usuario${NC}"
            exit 1
        fi
    fi
}

verify_system() {
    print_header "Verificando el sistema..."
    
    if [ -f "Scripts/verify-essential-packages" ]; then
        chmod +x Scripts/verify-essential-packages
        ./Scripts/verify-essential-packages
    fi
    
    if [ -f "Scripts/system-health-check" ]; then
        chmod +x Scripts/system-health-check
        ./Scripts/system-health-check
    fi
    
    if [ -f "Scripts/show-summary" ]; then
        chmod +x Scripts/show-summary
        ./Scripts/show-summary
    fi
}

TOTAL_STEPS=6

# Banner inicial
clear
print_header "🚀 INSTALADOR COMPLETO - ARCH LINUX + HYPRLAND"
echo -e "${YELLOW}Este script ejecutará todos los pasos de instalación en orden${NC}"
echo -e "${RED}ADVERTENCIA: El instalador formateará los discos en el paso 2${NC}"
echo -e "${YELLOW}Tiempo estimado: 2-3 horas${NC}\n"

# Confirmación inicial
echo -e "${YELLOW}¿Estás seguro de que quieres proceder? (s/N): ${NC}"
read confirm
if [[ $confirm != "s" && $confirm != "S" ]]; then
    echo -e "${RED}Instalación cancelada por el usuario${NC}"
    exit 1
fi

# PASO 1: Preparar Scripts
print_step "1" "Preparando scripts (2-5 minutos)"
if confirm_step; then
    chmod +x prepare-scripts.sh
    ./prepare-scripts.sh
    check_success
fi

# PASO 2: Instalación Principal
print_step "2" "Instalación principal de Arch Linux + Hyprland (60-120 minutos)"
echo -e "${RED}⚠️  ADVERTENCIA: Este paso formateará los discos${NC}"
if confirm_step; then
    chmod +x arch-hyprland-installer.sh
    ./arch-hyprland-installer.sh
    check_success
fi

# PASO 3: Optimizaciones
print_step "3" "Aplicando optimizaciones post-instalación (15-30 minutos)"
if confirm_step; then
    chmod +x post-install-optimizations.sh
    ./post-install-optimizations.sh
    check_success
fi

# Verificación intermedia
verify_system

# PASO 4: Mejoras
print_step "4" "Aplicando mejoras adicionales (5-10 minutos)"
if confirm_step; then
    chmod +x apply-improvements.sh
    ./apply-improvements.sh
    check_success
fi

# PASO 5: Corrección de Errores
print_step "5" "Corrección de errores (5-30 minutos)"
if confirm_step; then
    chmod +x fix-config-errors.sh
    ./fix-config-errors.sh
    check_success
fi

# Verificación intermedia
verify_system

# PASO 6: Configuración Avanzada
print_step "6" "Configuración avanzada (10-20 minutos)"
if confirm_step; then
    chmod +x advanced-config.sh
    ./advanced-config.sh
    check_success
fi

# Verificación final
print_header "🔍 Verificación Final del Sistema"
verify_system

# Resumen final
print_header "🎉 INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✓ Todos los pasos han sido ejecutados${NC}"
echo -e "\n${CYAN}Herramientas disponibles:${NC}"
echo -e "${YELLOW}- Scripts/script-guide${NC} - Navegador interactivo de scripts"
echo -e "${YELLOW}- Scripts/system-health-check${NC} - Diagnóstico completo"
echo -e "${YELLOW}- Scripts/show-summary${NC} - Resumen del sistema"
echo -e "\n${CYAN}Documentación:${NC}"
echo -e "${YELLOW}- INSTALLATION-ORDER-GUIDE.md${NC} - Guía detallada"
echo -e "${YELLOW}- README.md${NC} - Documentación general"

echo -e "\n${GREEN}¡Gracias por usar el instalador! 🚀${NC}"
