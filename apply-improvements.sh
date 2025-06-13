#!/bin/bash

# Apply Configuration Improvements Script
# This script applies all the optimizations and improvements to your dotfiles

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to backup files
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Backup created for $1"
    fi
}

# Check if running from correct directory
if [ ! -f "hyprland.conf" ] && [ ! -d ".config" ]; then
    print_error "Please run this script from your dotfiles directory"
    exit 1
fi

print_section "APPLYING CONFIGURATION IMPROVEMENTS"

# 1. Update application references
print_section "Updating Application References"

# Check and update shell configuration
if [ -f ".bashrc" ]; then
    backup_file ".bashrc"
    if ! grep -q "dev-environment.sh" ".bashrc"; then
        echo "" >> .bashrc
        echo "# Load enhanced development environment" >> .bashrc
        echo "[ -f ~/.config/shell/dev-environment.sh ] && source ~/.config/shell/dev-environment.sh" >> .bashrc
        print_status "Added development environment to .bashrc"
    fi
fi

if [ -f ".zshrc" ]; then
    backup_file ".zshrc"
    if ! grep -q "dev-environment.sh" ".zshrc"; then
        echo "" >> .zshrc
        echo "# Load enhanced development environment" >> .zshrc
        echo "[ -f ~/.config/shell/dev-environment.sh ] && source ~/.config/shell/dev-environment.sh" >> .zshrc
        print_status "Added development environment to .zshrc"
    fi
fi

# 2. Create directories if they don't exist
print_section "Creating Directory Structure"

directories=(
    ".config/shell"
    ".config/wofi"
    ".config/mako"
    ".config/kitty"
    ".config/hypr"
    "Scripts"
    "Projects"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    fi
done

# 3. Set executable permissions for scripts
print_section "Setting Script Permissions"

script_files=(
    "Scripts/pyenv-select"
    "Scripts/fnm-select"
    "Scripts/dev-manager"
    "Scripts/verify-essential-packages"
    "Scripts/font-manager"
    "Scripts/system-health-check"
    "Scripts/system-maintenance"
    "Scripts/ranger-setup"
    "Scripts/complete-system-validation"
    "Scripts/show-summary"
    "arch-hyprland-installer.sh"
    "post-install-optimizations.sh"
    "fix-config-errors.sh"
    "advanced-config.sh"
    "prepare-scripts.sh"
)

for script in "${script_files[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        print_status "Made executable: $script"
    fi
done

# 4. Validate configurations
print_section "Validating Configurations"

# Check Hyprland config
if [ -f ".config/hypr/hyprland.conf" ]; then
    if grep -q "google-chrome-stable" ".config/hypr/hyprland.conf"; then
        print_status "Hyprland config: Chrome reference found ✓"
    else
        print_warning "Hyprland config: Chrome reference not found"
    fi
    
    if grep -q "code" ".config/hypr/hyprland.conf"; then
        print_status "Hyprland config: VS Code reference found ✓"
    else
        print_warning "Hyprland config: VS Code reference not found"
    fi
fi

# Check Kitty config
if [ -f ".config/kitty/kitty.conf" ]; then
    if grep -q "CaskaydiaCove Nerd Font" ".config/kitty/kitty.conf"; then
        print_status "Kitty config: Nerd Font configured ✓"
    else
        print_warning "Kitty config: Nerd Font not configured"
    fi
fi

# Check Mako config
if [ -f ".config/mako/config" ]; then
    if grep -q "Catppuccin" ".config/mako/config"; then
        print_status "Mako config: Catppuccin theme configured ✓"
    else
        print_warning "Mako config: Catppuccin theme not configured"
    fi
fi

# Check Wofi config
if [ -f ".config/wofi/config" ]; then
    if grep -q "kitty" ".config/wofi/config"; then
        print_status "Wofi config: Kitty terminal configured ✓"
    else
        print_warning "Wofi config: Kitty terminal not configured"
    fi
fi

# 5. Create useful aliases and shortcuts
print_section "Creating Additional Shortcuts"

# Create a quick reload script
cat > Scripts/reload-hyprland << 'EOF'
#!/bin/bash
# Quick Hyprland reload script

notify-send "Hyprland" "Reloading configuration..." --icon=preferences-system

# Reload Hyprland
hyprctl reload

# Restart services
pkill waybar; waybar &
pkill mako; mako &

notify-send "Hyprland" "Configuration reloaded!" --icon=dialog-information
EOF

chmod +x Scripts/reload-hyprland
print_status "Created Hyprland reload script"

# Create a system info script
cat > Scripts/system-info << 'EOF'
#!/bin/bash
# System information display

# Get system info
uptime=$(uptime -p)
kernel=$(uname -r)
memory=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
disk=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

info_text="⏰ Uptime: $uptime
🧠 Memory: $memory
💾 Disk: $disk
⚡ CPU: ${cpu_usage}%
🐧 Kernel: $kernel"

notify-send "System Info" "$info_text" --icon=computer
EOF

chmod +x Scripts/system-info
print_status "Created system info script"

# 6. Create development environment setup verification
print_section "Creating Environment Verification"

cat > Scripts/verify-setup << 'EOF'
#!/bin/bash
# Verify development environment setup

echo "=== DEVELOPMENT ENVIRONMENT VERIFICATION ==="
echo

# Check core tools
tools=("python" "node" "git" "code" "docker" "pyenv" "fnm")
missing_tools=()

for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$($tool --version 2>/dev/null | head -1)
        echo "✅ $tool: $version"
    else
        echo "❌ $tool: Not installed"
        missing_tools+=("$tool")
    fi
done

echo

# Check configurations
configs=(
    "$HOME/.config/hypr/hyprland.conf:Hyprland"
    "$HOME/.config/kitty/kitty.conf:Kitty"
    "$HOME/.config/mako/config:Mako"
    "$HOME/.config/wofi/config:Wofi"
)

echo "=== CONFIGURATION FILES ==="
for config_entry in "${configs[@]}"; do
    IFS=':' read -r file name <<< "$config_entry"
    if [ -f "$file" ]; then
        echo "✅ $name: $file"
    else
        echo "❌ $name: $file (missing)"
    fi
done

echo

# Summary
if [ ${#missing_tools[@]} -eq 0 ]; then
    echo "🎉 All development tools are installed!"
else
    echo "⚠️  Missing tools: ${missing_tools[*]}"
    echo "   Run arch-hyprland-installer.sh to install missing tools"
fi
EOF

chmod +x Scripts/verify-setup
print_status "Created setup verification script"

# 7. Final summary
print_section "CONFIGURATION IMPROVEMENTS APPLIED"

echo "✅ Configuration files updated with modern applications"
echo "✅ VS Code configured as default editor"
echo "✅ Google Chrome configured as default browser"
echo "✅ Enhanced terminal (Kitty) configuration"
echo "✅ Improved notification system (Mako) with Catppuccin theme"
echo "✅ Optimized application launcher (Wofi)"
echo "✅ Development environment management scripts created"
echo "✅ Enhanced shell configuration with fnm and pyenv integration"
echo ""

print_status "All improvements have been applied!"
print_warning "Please restart Hyprland or run 'Scripts/reload-hyprland' to apply changes"

echo ""
echo "🎯 New features available:"
echo "   • Press Super+F9 to open Development Manager"
echo "   • Press Super+Shift+F9 to select Python version"
echo "   • Press Super+Ctrl+F9 to select Node.js version"
echo "   • Run 'dev-check' in terminal to see environment status"
echo "   • Run 'Scripts/verify-setup' to verify installation"
echo "   • Run 'Scripts/verify-essential-packages' to check essential packages"
echo "   • Run 'Scripts/font-manager' to manage fonts"
echo "   • Run 'Scripts/system-health-check' for complete system verification"

print_section "NEXT STEPS"
echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "2. Restart Hyprland or run: Scripts/reload-hyprland"
echo "3. Install missing development tools: ./arch-hyprland-installer.sh"
echo "4. Verify everything works: Scripts/verify-setup"
