#!/bin/bash

# =============================================================================
# CONFIGURACIONES ADICIONALES AVANZADAS
# Script para configuraciones específicas de desarrollo y personalización
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
# CONFIGURACIONES DE DESARROLLO ESPECÍFICAS
# =============================================================================

setup_development_configs() {
    print_step "Configurando entornos de desarrollo específicos"
    
    # Configuración de VS Code
    print_status "Configurando Visual Studio Code"
    mkdir -p ~/.config/Code/User
    
    cat > ~/.config/Code/User/settings.json << 'EOF'
{
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "editor.fontFamily": "'CaskaydiaCove Nerd Font Mono', monospace",
    "editor.fontSize": 14,
    "editor.lineHeight": 1.6,
    "editor.fontLigatures": true,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": true,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": "explicit",
        "source.organizeImports": "explicit"
    },
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "terminal.integrated.fontFamily": "'CaskaydiaCove Nerd Font Mono'",
    "terminal.integrated.fontSize": 13,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "python.defaultInterpreterPath": "~/.pyenv/shims/python",
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "javascript.updateImportsOnFileMove.enabled": "always",
    "typescript.updateImportsOnFileMove.enabled": "always",
    "emmet.includeLanguages": {
        "javascript": "javascriptreact",
        "typescript": "typescriptreact"
    },
    "window.titleBarStyle": "custom",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false
}
EOF

    # Extensiones recomendadas para VS Code
    cat > ~/.config/Code/User/extensions.json << 'EOF'
{
    "recommendations": [
        "catppuccin.catppuccin-vsc",
        "catppuccin.catppuccin-vsc-icons",
        "ms-python.python",
        "ms-python.black-formatter",
        "ms-python.pylint",
        "ms-vscode.vscode-typescript-next",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode",
        "ms-vscode.vscode-eslint",
        "rust-lang.rust-analyzer",
        "golang.go",
        "ms-vscode.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "gitpod.gitpod-desktop",
        "github.copilot",
        "github.copilot-chat",
        "ms-vscode-remote.remote-ssh",
        "ms-vscode-remote.remote-containers",
        "formulahendry.auto-rename-tag",
        "christian-kohler.path-intellisense",
        "visualstudioexptteam.vscodeintellicode",
        "gruntfuggly.todo-tree",
        "wayou.vscode-todo-highlight",
        "ms-vscode.live-server"
    ]
}
EOF

    print_status "VS Code configurado"
}

setup_git_advanced() {
    print_step "Configurando Git avanzado"
    
    # Configuración global avanzada de Git
    git config --global core.autocrlf input
    git config --global core.safecrlf warn
    git config --global color.ui auto
    git config --global color.branch.current "yellow reverse"
    git config --global color.branch.local yellow
    git config --global color.branch.remote green
    git config --global color.diff.meta "yellow bold"
    git config --global color.diff.frag "magenta bold"
    git config --global color.diff.old "red bold"
    git config --global color.diff.new "green bold"
    git config --global color.status.added yellow
    git config --global color.status.changed green
    git config --global color.status.untracked cyan
    
    # Aliases útiles
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.visual "!gitk"
    git config --global alias.graph "log --oneline --graph --decorate --all"
    git config --global alias.aliases "config --get-regexp alias"
    git config --global alias.amend "commit --amend --no-edit"
    git config --global alias.whoami "config user.email"
    
    print_status "Git avanzado configurado"
}

setup_tmux_advanced() {
    print_step "Configurando Tmux avanzado"
    
    cat > ~/.tmux.conf << 'EOF'
# Configuración avanzada de Tmux

# Cambiar prefix
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Configuración básica
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color*:Tc"
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g mouse on

# Configuración de escape time
set -sg escape-time 0
set -g repeat-time 1000

# Configuración de status bar
set -g status-position top
set -g status-justify left
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left ''
set -g status-right '#[fg=#89b4fa,bg=#1e1e2e] %Y-%m-%d #[fg=#cdd6f4,bg=#313244] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

setw -g window-status-current-style 'fg=#1e1e2e bg=#89b4fa bold'
setw -g window-status-current-format ' #I#[fg=#1e1e2e]:#[fg=#1e1e2e]#W#[fg=#1e1e2e]#F '

setw -g window-status-style 'fg=#89b4fa bg=#313244'
setw -g window-status-format ' #I#[fg=#cdd6f4]:#[fg=#cdd6f4]#W#[fg=#cdd6f4]#F '

setw -g window-status-bell-style 'fg=#f38ba8 bg=#1e1e2e bold'

# Configuración de paneles
set -g pane-border-style 'fg=#313244'
set -g pane-active-border-style 'fg=#89b4fa'

# Mensajes
set -g message-style 'fg=#1e1e2e bg=#89b4fa bold'

# Keybindings mejorados
bind | split-window -h -c '#{pane_current_path}'
bind - split-window -v -c '#{pane_current_path}'
bind c new-window -c '#{pane_current_path}'

# Navegación de paneles estilo vim
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Redimensionar paneles
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Copiar modo vim
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'wl-copy'
bind -T copy-mode-vi r send-keys -X rectangle-toggle

# Recargar configuración
bind r source-file ~/.tmux.conf \; display "¡Configuración recargada!"

# Plugins (TPM)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'catppuccin/tmux'

# Configuración de plugins
set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'

# Inicializar TPM (mantener al final)
run '~/.tmux/plugins/tpm/tpm'
EOF

    # Instalar TPM
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true
    
    print_status "Tmux avanzado configurado"
}

setup_shell_enhancements() {
    print_step "Configurando mejoras del shell"
    
    # Instalar Starship
    if ! command -v starship &> /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
    
    # Configuración de Starship
    mkdir -p ~/.config
    cat > ~/.config/starship.toml << 'EOF'
format = """
[╭─](bold blue)$username$hostname$directory$git_branch$git_status$python$nodejs$rust$golang$docker_context
[╰─](bold blue)$character"""

right_format = """$cmd_duration$time"""

[username]
style_user = "bold cyan"
style_root = "bold red"
format = "[$user]($style) "
show_always = true

[hostname]
ssh_only = false
format = "[@$hostname](bold green) "

[directory]
style = "bold purple"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "bold yellow"

[git_status]
style = "bold red"

[python]
symbol = " "
style = "bold blue"

[nodejs]
symbol = " "
style = "bold green"

[rust]
symbol = " "
style = "bold orange"

[golang]
symbol = " "
style = "bold cyan"

[docker_context]
symbol = " "
style = "bold blue"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[cmd_duration]
min_time = 2_000
format = "took [$duration](bold yellow)"

[time]
disabled = false
format = '🕙[\[ $time \]](bold blue) '
time_format = "%T"
EOF

    print_status "Mejoras del shell configuradas"
}

setup_neovim_config() {
    print_step "Configurando Neovim"
    
    # Crear configuración básica de Neovim
    mkdir -p ~/.config/nvim
    
    cat > ~/.config/nvim/init.lua << 'EOF'
-- Configuración básica de Neovim
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.softtabstop = 4
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keymaps básicos
vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>w', ':w<CR>')
vim.keymap.set('n', '<leader>q', ':q<CR>')
vim.keymap.set('n', '<leader>x', ':x<CR>')
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Auto install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin-mocha"
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin"
        }
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
    end,
  },
})
EOF

    print_status "Neovim configurado"
}

create_development_aliases() {
    print_step "Creando aliases de desarrollo"
    
    cat >> ~/.zshrc << 'EOF'

# Aliases de desarrollo adicionales
alias ll='exa -la --icons'
alias la='exa -a --icons'
alias lt='exa --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias ps='procs'
alias du='dust'
alias df='duf'
alias ping='gping'

# Git aliases avanzados
alias gst='git status'
alias gaa='git add .'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gps='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gbr='git branch'
alias gbd='git branch -d'
alias glg='git log --oneline --graph --decorate'
alias gdf='git diff'
alias grs='git reset'
alias grh='git reset --hard'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker system prune -f'

# Python/Node aliases
alias py='python'
alias py3='python3'
alias pip='pip3'
alias venv='python -m venv'
alias act='source venv/bin/activate'
alias deact='deactivate'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nr='npm run'
alias nrs='npm run start'
alias nrd='npm run dev'
alias nrb='npm run build'
alias ys='yarn start'
alias yd='yarn dev'
alias yb='yarn build'
alias ya='yarn add'
alias yad='yarn add --dev'

# Sistema
alias reload='source ~/.zshrc'
alias zshconfig='nvim ~/.zshrc'
alias hyprconfig='nvim ~/.config/hypr/hyprland.conf'
alias update='yay -Syu'
alias clean='yay -Sc && yay -Yc'
alias search='yay -Ss'
alias install='yay -S'
alias remove='yay -R'
alias orphans='yay -Qtdq | yay -Rns -'

# Funciones útiles
mkcd() { mkdir -p "$1" && cd "$1"; }
backup() { cp "$1"{,.bak}; }
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' no se puede extraer con extract()" ;;
        esac
    else
        echo "'$1' no es un archivo válido!"
    fi
}

# Función para cambiar a directorios de proyecto rápidamente
proj() {
    case $1 in
        "")
            cd ~/Projects
            ;;
        *)
            cd ~/Projects/$1
            ;;
    esac
}

# Función para crear proyecto Node.js rápido
newnode() {
    mkdir -p ~/Projects/$1
    cd ~/Projects/$1
    fnm use 20
    npm init -y
    npm install --save-dev nodemon
    echo "console.log('Hello, $1!');" > index.js
    echo "node_modules/" > .gitignore
    git init
    echo "Proyecto $1 creado en ~/Projects/$1"
}

# Función para crear proyecto Python rápido
newpy() {
    mkdir -p ~/Projects/$1
    cd ~/Projects/$1
    pyenv local 3.11.7
    python -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    echo "print('Hello, $1!')" > main.py
    echo "venv/" > .gitignore
    echo "__pycache__/" >> .gitignore
    echo "*.pyc" >> .gitignore
    git init
    echo "Proyecto $1 creado en ~/Projects/$1"
}
EOF

    print_status "Aliases de desarrollo creados"
}

# =============================================================================
# MENÚ PRINCIPAL
# =============================================================================

show_config_menu() {
    while true; do
        clear
        echo -e "${CYAN}CONFIGURACIONES ADICIONALES AVANZADAS${NC}"
        echo -e "${WHITE}=======================================${NC}"
        echo
        echo -e "${GREEN}1.${NC}  Configurar entornos de desarrollo"
        echo -e "${GREEN}2.${NC}  Configurar Git avanzado"
        echo -e "${GREEN}3.${NC}  Configurar Tmux avanzado"
        echo -e "${GREEN}4.${NC}  Configurar mejoras del shell"
        echo -e "${GREEN}5.${NC}  Configurar Neovim"
        echo -e "${GREEN}6.${NC}  Crear aliases de desarrollo"
        echo -e "${GREEN}7.${NC}  Aplicar todas las configuraciones"
        echo -e "${GREEN}0.${NC}  Salir"
        echo
        
        read -p "$(echo -e "${CYAN}Selecciona una opción: ${NC}")" choice
        
        case $choice in
            1) setup_development_configs ;;
            2) setup_git_advanced ;;
            3) setup_tmux_advanced ;;
            4) setup_shell_enhancements ;;
            5) setup_neovim_config ;;
            6) create_development_aliases ;;
            7) 
                setup_development_configs
                setup_git_advanced
                setup_tmux_advanced
                setup_shell_enhancements
                setup_neovim_config
                create_development_aliases
                ;;
            0) exit 0 ;;
            *) echo "Opción inválida" ;;
        esac
        
        read -p "Presiona Enter para continuar..."
    done
}

main() {
    echo -e "${CYAN}CONFIGURACIONES ADICIONALES AVANZADAS${NC}"
    echo -e "${WHITE}=====================================${NC}"
    echo
    echo "Este script configurará herramientas avanzadas de desarrollo"
    echo "y personalizará el entorno para máxima productividad."
    echo
    
    show_config_menu
}

main "$@"
