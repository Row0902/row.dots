#!/bin/bash
# ─── Bootstrap ──────────────────────────────────────────────────────────
# Configura una máquina nueva después de chezmoi init --apply.
#
# Uso:
#   (chezmoi source-path)/scripts/bootstrap.sh
#   # o si estás en el repo:
#   ./scripts/bootstrap.sh
#
# Hace (solo lo interactivo: brew bundle, chsh e identidad los resuelve chezmoi):
#   1. Detecta / importa / genera claves SSH
#   2. gh auth login
#   3. Cambia remote a SSH
#
# Es IDEMPOTENTE — podés correrlo varias veces sin romper nada.
# ────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colores ────────────────────────────────────────────────────────────
BOLD='\033[1m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}→${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }

# Detectar directorio del repo
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BOLD}
╔══════════════════════════════════════════╗
║      Bienvenido al bootstrap de 🏡       ║
║  Configurando tu máquina nueva...        ║
╚══════════════════════════════════════════╝${NC}
"

# ═══════════════════════════════════════════════════════════════════════
# FASE 1: Homebrew
# ═══════════════════════════════════════════════════════════════════════

phase_1_install_tools() {
    info "Fase 0: herramientas (las provisiona chezmoi)"

    # La lista de paquetes es propiedad de run_once_before_install-homebrew.sh.tmpl.
    # Este script no mantiene una copia propia: dos dueños divergen.
    if command -v fish &>/dev/null && command -v starship &>/dev/null; then
        ok "Tools ya instaladas por chezmoi"
        return 0
    fi

    info "Faltan tools: corriendo 'chezmoi apply' para disparar el run_once..."
    if command -v chezmoi &>/dev/null; then
        chezmoi apply || warn "chezmoi apply tuvo issues; resolvé el error y reintentá"
    else
        warn "chezmoi no está en PATH. Corré 'chezmoi apply' y volvé a ejecutar este script."
    fi
}

phase_1_install_tools

# ═══════════════════════════════════════════════════════════════════════
# FASE 2: Git identidad local
# ═══════════════════════════════════════════════════════════════════════

info "Fase 0: Git identidad"

# ~/.gitconfig.local lo gestiona chezmoi (dot_gitconfig.local.tmpl): la identidad
# sale de los prompts de init y la signing key SSH se resuelve sola. Escribirlo
# acá peleaba con el próximo 'chezmoi apply'.
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ -f "$GITCONFIG_LOCAL" ] && grep -q "\[user\]" "$GITCONFIG_LOCAL" 2>/dev/null; then
    ok "Identidad de Git presente (gestionada por chezmoi)"
else
    warn "Falta la identidad: corré 'chezmoi init' para responder los prompts y después 'chezmoi apply'."
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 2: Fish shell
# ═══════════════════════════════════════════════════════════════════════

info "Fase 0: Fish shell"

# La entrada en /etc/shells y el cambio de shell por defecto los resuelve
# run_once_before_install-homebrew.sh.tmpl. No se duplican acá.

# ═══════════════════════════════════════════════════════════════════════
# FASE 3: SSH
# ═══════════════════════════════════════════════════════════════════════

info "Fase 1/3: SSH"

detect_ssh_keys() {
    local dir="$1"
    for f in "$dir"/*; do
        [ -f "$f" ] || continue
        case "${f##*/}" in
            *.pub|known_hosts|authorized_keys|config|environment) continue ;;
        esac
        if file "$f" | grep -qi "private key"; then
            echo "$f"
        fi
    done
}

ssh_keys=()
# Declared here so `set -u` is satisfied on any non-WSL machine; only the WSL
# branch below fills it.
win_keys=()
while IFS= read -r -d '' key; do
    ssh_keys+=("$key")
done < <(detect_ssh_keys "$HOME/.ssh" | tr '\n' '\0')

if [ ${#ssh_keys[@]} -gt 0 ]; then
    ok "Claves SSH encontradas en ~/.ssh/:"
    for key in "${ssh_keys[@]}"; do
        echo "   • $key"
    done
    echo ""
    read -rp "¿Usar estas claves y cambiar remote a SSH? (S/n): " choice
    if [[ ! "$choice" =~ ^[Nn] ]]; then
        setup_ssh_remote=true
    fi
else
    info "No se encontraron claves SSH en ~/.ssh/"

    # WSL: buscar en Windows
    if grep -qi microsoft /proc/version 2>/dev/null; then
        info "Ejecutando en WSL"

        # Buscar usuario de Windows
        win_user=$(ls /mnt/c/Users/ 2>/dev/null | grep -v "^Public$\|^Default$" | head -1)
        win_ssh_dir="/mnt/c/Users/$win_user/.ssh"

        if [ -n "$win_user" ] && [ -d "$win_ssh_dir" ]; then
            win_keys=()
            while IFS= read -r -d '' key; do
                win_keys+=("$key")
            done < <(detect_ssh_keys "$win_ssh_dir" | tr '\n' '\0')

            if [ ${#win_keys[@]} -gt 0 ]; then
                echo ""
                warn "Se encontraron claves SSH en Windows ($win_ssh_dir):"
                for key in "${win_keys[@]}"; do
                    echo "   • $key"
                done
                echo ""
                read -rp "¿Importar estas claves a WSL? (S/n): " import_choice
                if [[ ! "$import_choice" =~ ^[Nn] ]]; then
                    mkdir -p "$HOME/.ssh"
                    for key in "${win_keys[@]}"; do
                        cp "$key" "$HOME/.ssh/"
                        chmod 600 "$HOME/.ssh/$(basename "$key")"
                        pub_key="${key}.pub"
                        if [ -f "$pub_key" ]; then
                            cp "$pub_key" "$HOME/.ssh/"
                            chmod 644 "$HOME/.ssh/$(basename "$pub_key")"
                        fi
                        ok "Importada: $(basename "$key")"
                    done
                    setup_ssh_remote=true
                fi
            fi
        fi
    fi

    # Si aún no hay claves, ofrecer generar
    if [ "${#ssh_keys[@]}" -eq 0 ] && [ "${#win_keys[@]}" -eq 0 ]; then
        echo ""
        read -rp "¿Generar nueva clave SSH ed25519? (S/n): " gen_choice
        if [[ ! "$gen_choice" =~ ^[Nn] ]]; then
            read -rp "Email para la clave SSH: " ssh_email
            ssh-keygen -t ed25519 -C "$ssh_email"
            eval "$(ssh-agent -s)"
            ssh-add "$HOME/.ssh/id_ed25519"
            ok "Clave SSH generada"

            # gh auth + add key
            if command -v gh &>/dev/null; then
                info "Autenticando en GitHub para agregar la clave..."
                gh auth login
                gh ssh-key add "$HOME/.ssh/id_ed25519.pub"
                ok "Clave SSH agregada a GitHub"
            fi

            setup_ssh_remote=true
        fi
    fi
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 4: GitHub Auth
# ═══════════════════════════════════════════════════════════════════════

info "Fase 2/3: GitHub CLI"

if command -v gh &>/dev/null; then
    if ! gh auth status &>/dev/null; then
        info "Autenticando gh CLI..."
        gh auth login
        ok "gh CLI autenticado"
    else
        ok "gh CLI ya autenticado"
    fi
else
    warn "gh no está instalado, omitiendo autenticación"
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 5: Remote SSH
# ═══════════════════════════════════════════════════════════════════════

info "Fase 3/3: Remote"

if [ "${setup_ssh_remote:-false}" = true ]; then
    remote_url="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")"
    if echo "$remote_url" | grep -q "^https://"; then
        info "Cambiando remote de HTTPS a SSH..."
        git -C "$REPO_DIR" remote set-url origin git@github.com:Row0902/row.dots.git
        ok "Remote cambiado a SSH"
    else
        ok "Remote ya está en SSH"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════
# FIN
# ═══════════════════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}${BOLD}✓ Bootstrap completo.${NC}"
echo ""
echo "  Recordá:"
echo "  • Los cambios de shell son efectivos al próximo login (o exec fish)"
echo "  • Git config local se configuró con chezmoi prompt"
echo "  • Cualquier fase podés re-ejecutarla con: $0"
echo ""
