#!/usr/bin/env pwsh
# ─── Bootstrap ──────────────────────────────────────────────────────────
# Configura una máquina nueva Windows después de chezmoi init --apply.
#
# Uso:
#   pwsh $env:USERPROFILE\.local\share\chezmoi\scripts\bootstrap.ps1
#   # o si estás en el repo:
#   pwsh .\scripts\bootstrap.ps1
#
# Hace (solo lo interactivo: los paquetes los provisiona el run_once de chezmoi):
#   1. Detecta / importa / genera claves SSH + ssh-agent
#   2. gh auth login
#   3. Cambia remote a SSH
#
# Es IDEMPOTENTE — podés correrlo varias veces sin romper nada.
# ────────────────────────────────────────────────────────────────────────

#Requires -Version 5.1

# ── Output Helpers ──────────────────────────────────────────────────────
function Write-BootstrapInfo  { Write-Host "→ $args" -ForegroundColor Cyan }
function Write-BootstrapOk    { Write-Host "✓ $args" -ForegroundColor Green }
function Write-BootstrapWarn  { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-BootstrapError { Write-Host "✗ $args" -ForegroundColor Red }

# ── Admin Check ─────────────────────────────────────────────────────────
function Test-AdminElevation {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ═══════════════════════════════════════════════════════════════════════
# FASE 1: Scoop + Tools
# ═══════════════════════════════════════════════════════════════════════

function Invoke-ChezmoiProvisioning {
    Write-BootstrapInfo "Phase 1: Tools (provisioned by chezmoi)"

    # Package installation is owned by run_once_before_install-packages.ps1.tmpl.
    # This script must never keep its own copy of the list: two owners drift.
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-BootstrapOk "Tools ya instaladas por chezmoi"
        return
    }

    Write-BootstrapInfo "Faltan tools: corriendo 'chezmoi apply' para disparar el run_once..."
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        chezmoi apply
    } else {
        Write-BootstrapWarn "chezmoi no está en PATH. Corré 'chezmoi apply' y volvé a ejecutar este script."
    }
}

# ═══════════════════════════════════════════════════════════════════════
# FASE 2: Git identidad local
# ═══════════════════════════════════════════════════════════════════════

function Test-GitIdentity {
    Write-BootstrapInfo "Phase 2: Git identidad"

    # ~/.gitconfig.local lo gestiona chezmoi (dot_gitconfig.local.tmpl): la
    # identidad sale de los prompts de init y la signing key SSH se resuelve
    # sola. Escribirlo acá peleaba con el próximo 'chezmoi apply'.
    $gitconfigLocal = Join-Path $env:USERPROFILE ".gitconfig.local"
    if ((Test-Path $gitconfigLocal) -and (Select-String -Path $gitconfigLocal -Pattern '\[user\]' -Quiet)) {
        Write-BootstrapOk "Identidad de Git presente (gestionada por chezmoi)"
    } else {
        Write-BootstrapWarn "Falta la identidad: corré 'chezmoi init' para responder los prompts y después 'chezmoi apply'."
    }
}

# ═══════════════════════════════════════════════════════════════════════
# FASE 3: SSH
# ═══════════════════════════════════════════════════════════════════════

function Setup-SSHKeys {
    Write-BootstrapInfo "Phase 3: SSH"

    $sshDir = Join-Path $env:USERPROFILE ".ssh"
    $setupRemote = $false

    function Get-PrivateKeyFiles($dir) {
        if (-not (Test-Path $dir)) { return @() }
        $keys = @()
        Get-ChildItem $dir -File | ForEach-Object {
            $name = $_.Name
            if ($name -match '\.pub$|^known_hosts$|^authorized_keys$|^config$|^environment$') { return }
            $firstLine = Get-Content $_.FullName -TotalCount 1
            if ($firstLine -match '^-----BEGIN (OPENSSH|RSA|DSA|EC|ED25519) PRIVATE KEY-----') {
                $keys += $_
            }
        }
        return $keys
    }

    $sshKeys = Get-PrivateKeyFiles $sshDir

    if ($sshKeys.Count -gt 0) {
        Write-BootstrapOk "Claves SSH encontradas en ~/.ssh/:"
        $sshKeys | ForEach-Object { Write-Host "   • $_" }
        $choice = Read-Host "`n¿Usar estas claves? (S/n)"
        if ($choice -notmatch '^[Nn]') {
            $setupRemote = $true
            Write-BootstrapOk "Usando claves existentes"
        }
    } else {
        Write-BootstrapInfo "No se encontraron claves SSH en ~/.ssh/"
        $genChoice = Read-Host "¿Generar nueva clave SSH ed25519? (S/n)"
        if ($genChoice -notmatch '^[Nn]') {
            $sshEmail = Read-Host "Email para la clave SSH"
            ssh-keygen -t ed25519 -C "$sshEmail"
            Write-BootstrapOk "Clave SSH generada"

            # Enable and start ssh-agent
            Write-BootstrapInfo "Configurando ssh-agent..."
            try {
                Set-Service ssh-agent -StartupType Automatic -ErrorAction Stop
                Start-Service ssh-agent -ErrorAction Stop
                Write-BootstrapOk "ssh-agent configurado e iniciado"
            } catch {
                Write-BootstrapWarn "No se pudo configurar ssh-agent (¿ejecutás como Admin?)"
            }

            # Add key to agent
            $keyPath = Join-Path $sshDir "id_ed25519"
            ssh-add $keyPath 2>$null

            # Offer to add to GitHub
            if (Get-Command "gh" -ErrorAction SilentlyContinue) {
                $ghAddChoice = Read-Host "¿Agregar la clave a GitHub via gh? (S/n)"
                if ($ghAddChoice -notmatch '^[Nn]') {
                    $pubKeyPath = Join-Path $sshDir "id_ed25519.pub"
                    gh ssh-key add $pubKeyPath
                    Write-BootstrapOk "Clave SSH agregada a GitHub"
                }
            }

            $setupRemote = $true
        }
    }

    return $setupRemote
}

# ═══════════════════════════════════════════════════════════════════════
# FASE 5: GitHub Auth
# ═══════════════════════════════════════════════════════════════════════

function Setup-GitHubAuth {
    Write-BootstrapInfo "Phase 4: GitHub CLI"

    if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
        Write-BootstrapInfo "Instalando gh..."
        scoop install gh 2>&1 | Out-Null
        Write-BootstrapOk "gh instalado"
    }

    $ghStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-BootstrapInfo "Autenticando gh CLI..."
        gh auth login
        Write-BootstrapOk "gh CLI autenticado"
    } else {
        Write-BootstrapOk "gh CLI ya autenticado"
    }
}

# ═══════════════════════════════════════════════════════════════════════
# FASE 6: Remote SSH
# ═══════════════════════════════════════════════════════════════════════

function Convert-ToSshRemote {
    param(
        [bool]$setupRemote,
        [string]$repoDir
    )

    Write-BootstrapInfo "Phase 5: Remote"

    if (-not $setupRemote) {
        Write-BootstrapInfo "No hay claves SSH disponibles, omitiendo cambio de remote"
        return
    }

    $remoteUrl = git -C $repoDir remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-BootstrapWarn "No se pudo obtener remote URL"
        return
    }

    if ($remoteUrl -match '^https://') {
        Write-BootstrapInfo "Cambiando remote de HTTPS a SSH..."
        git -C $repoDir remote set-url origin git@github.com:Row0902/row.dots.git
        Write-BootstrapOk "Remote cambiado a SSH"
    } else {
        Write-BootstrapOk "Remote ya está en SSH"
    }
}

# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

Write-Host "╔══════════════════════════════════════╗" -ForegroundColor White
Write-Host "║      Bootstrap de 🏡  para Windows   ║" -ForegroundColor White
Write-Host "║  Configurando tu máquina nueva...    ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor White

# Repo root = parent of scripts/
$script:RepoDir = Split-Path $PSScriptRoot -Parent

# Check admin
$isAdmin = Test-AdminElevation
if (-not $isAdmin) {
    Write-BootstrapWarn "No ejecutando como Administrador. Algunas operaciones (ssh-agent) pueden fallar."
}

# Run phases
Invoke-ChezmoiProvisioning
Test-GitIdentity
$shouldSetupRemote = Setup-SSHKeys
Setup-GitHubAuth
Convert-ToSshRemote -setupRemote $shouldSetupRemote -repoDir $script:RepoDir

Write-Host ""
Write-Host "✓ Bootstrap completo." -ForegroundColor Green
Write-Host ""
Write-Host "  Recordá:"
Write-Host "  • fish y zellij no se instalan en Windows — usá WSL para esos"
Write-Host "  • Cualquier fase podés re-ejecutarla con: $PSCommandPath"
