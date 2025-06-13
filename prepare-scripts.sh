#!/bin/bash

# =============================================================================
# PREPARAR SCRIPTS DE INSTALACIÓN
# Script para hacer ejecutables y preparar los scripts de instalación
# =============================================================================

echo "🚀 Preparando scripts de instalación de Arch Linux + Hyprland"
echo "=============================================================="

# Hacer ejecutables todos los scripts
chmod +x arch-hyprland-installer.sh
chmod +x post-install-optimizations.sh
chmod +x fix-config-errors.sh
chmod +x advanced-config.sh

echo "✅ Scripts hechos ejecutables"

# Verificar que los scripts existen
scripts=("arch-hyprland-installer.sh" "post-install-optimizations.sh" "fix-config-errors.sh" "advanced-config.sh")

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ $script - Encontrado"
    else
        echo "❌ $script - No encontrado"
    fi
done

echo ""
echo "📋 Instrucciones de uso:"
echo "========================"
echo ""
echo "1. Para instalación completa de Arch Linux:"
echo "   sudo ./arch-hyprland-installer.sh"
echo ""
echo "2. Para optimizaciones post-instalación:"
echo "   ./post-install-optimizations.sh"
echo ""
echo "3. Para corregir errores de configuración:"
echo "   ./fix-config-errors.sh"
echo ""
echo "4. Para configuraciones avanzadas de desarrollo:"
echo "   ./advanced-config.sh"
echo ""
echo "🔧 Los scripts son modulares - puedes ejecutar solo las partes que necesites"
echo ""
echo "✨ Características principales:"
echo "   • fnm con Node.js 18, 20, 22"
echo "   • pyenv con Python 3.9-3.13"
echo "   • Google Chrome en lugar de Thorium"
echo "   • VS Code en lugar de Cursor"
echo "   • Múltiples fuentes Nerd Fonts"
echo "   • Temas GTK completos"
echo "   • Configuraciones optimizadas"
echo ""
echo "✨ ¡Todo listo para la instalación!"
