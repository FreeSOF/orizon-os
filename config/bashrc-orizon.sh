#!/bin/bash
export ORIZON_VERSION="Beta 3"
export ORIZON_BUILD="18-07-2026"
export ORIZON_LINK="https://freesof.ru/orizon-os"
export CLICOLOR=1
export TERM=xterm-256color

# ── Prompt ──────────────────────────────────────────────────
PS1='\[\033[0;36m\]┌─[\[\033[1;37m\]\u\[\033[0;36m\]@\[\033[0;34m\]orizon\[\033[0;36m\]] \[\033[0;33m\]\w\[\033[0m\]\n\[\033[0;36m\]└─\[\033[1;36m\]❯\[\033[0m\] '

# ── Navigation ───────────────────────────────────────────────
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── System ─────────────────────────────────────────────────
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias ports='ss -tulpn'
alias mem='free -h'
alias disk='df -h'
alias topcpu='ps aux --sort=-%cpu | head -10'
alias topmem='ps aux --sort=-%mem | head -10'
alias myip='curl -s https://api.ipify.org && echo'

# ── Safety ────────────────────────────────────────────
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ── Git ─────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --color'
alias gcl='git clone'

# ── iamroot ─────────────────────────────────────────────────
alias iamroot='sudo -i'

# ── ORIZON CLI ──────────────────────────────────────────────
orizon() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'

    case "$1" in
        --version|-v)
            echo -e "${CYAN}Version:${NC} ORIZON LINUX ${BOLD}${ORIZON_VERSION}${NC} STABLE, build: ${ORIZON_BUILD}"
            ;;
        --about|-a)
            echo -e "${CYAN}ORIZON Linux System${NC} — Intelligent Linux System"
            echo -e "${GREEN}${ORIZON_LINK}${NC}"
            ;;
        --info|-i)
            neofetch 2>/dev/null || true
            ;;
        --theme)
            if [ -z "$2" ]; then
                echo -e "${YELLOW}Usage:${NC} orizon --theme dark|light"
            else
                bash /opt/orizon/scripts/apply-kde-theme.sh "$2"
            fi
            ;;
        --update|-u)
            echo -e "${CYAN}[ORIZON]${NC} Updating system..."
            sudo bash /opt/orizon/scripts/update.sh
            ;;
        --wallpaper|-w)
            if [ -z "$2" ]; then
                echo -e "${YELLOW}Usage:${NC} orizon --wallpaper /path/to/file.png"
            else
                plasma-apply-wallpaperimage "$2" 2>/dev/null || \
                qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
                    var d=desktops()[0];
                    d.wallpaperPlugin='org.kde.image';
                    d.currentConfigGroup=['Wallpaper','org.kde.image','General'];
                    d.writeConfig('Image','file://${2}');
                " 2>/dev/null
                echo -e "${GREEN}✓${NC} Wallpaper: $2"
            fi
            ;;
        --help|-h|"")
            echo ""
            echo -e "${CYAN}${BOLD}ORIZON${NC} — CLI of system"
            echo ""
            echo -e "  ${CYAN}orizon --version${NC}           system version"
            echo -e "  ${CYAN}orizon --about${NC}             information and our site"
            echo -e "  ${CYAN}orizon --info${NC}              system information"
            echo -e "  ${CYAN}orizon --theme dark${NC}        dark theme"
            echo -e "  ${CYAN}orizon --theme light${NC}       light theme"
            echo -e "  ${CYAN}orizon --update${NC}            update system"
            echo -e "  ${CYAN}orizon --wallpaper /path/to/file/${NC}  change wallpapers"
            echo ""
            ;;
        *)
            echo -e "\033[0;31Unknown command::\033[0m $1"
            echo -e "Type ${CYAN}orizon --help${NC}"
            ;;
    esac
}

# ── Neofetch on terminal open ─────────────────────────
if [[ $- == *i* ]] && [[ -z "$ORIZON_GREETED" ]]; then
    export ORIZON_GREETED=1
    neofetch 2>/dev/null || true
fi

