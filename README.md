<div align="center">

# 🏡 row.dots

**Entorno de desarrollo minimalista, reproducible y multiplataforma.**  
Optimizado para **Windows 11** y **Linux**, gestionado declarativamente con [chezmoi](https://www.chezmoi.io/).

[![chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue?style=flat-square&logo=chezmoi)](https://www.chezmoi.io/)
[![starship](https://img.shields.io/badge/prompt-starship-red?style=flat-square&logo=starship)](https://starship.rs/)
[![license](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![git-signing](https://img.shields.io/badge/commits-ssh--signed-purple?style=flat-square&logo=git)](https://git-scm.com/)

</div>

---

## ⚡ Stack

| Componente | Herramienta | Propósito / Características |
| :--- | :--- | :--- |
| **Shell** | [Fish](https://fishshell.com/) / [Nushell](https://www.nushell.sh/) | Completado inteligente, sintaxis moderna y tipado estructurado |
| **Prompt** | [Starship](https://starship.rs/) | Diseño modular tipo cápsula (*pills*) Tokyo Night con badge de OS |
| **Gestión** | [chezmoi](https://www.chezmoi.io/) | Dotfiles basados en plantillas Go, soporte multi-OS y secretos |
| **Git & Diff** | [Delta](https://github.com/dandavison/delta) | Syntax highlighting, vistas side-by-side y firma criptográfica SSH |
| **Entornos** | [direnv](https://direnv.net/) | Carga automática de variables de entorno y layouts para Python (`uv`, `venv`) |
| **Productividad** | [zoxide](https://github.com/ajeetdsouza/zoxide), [eza](https://eza.rocks/), [bat](https://github.com/sharkdp/bat), [fzf](https://github.com/junegunn/fzf) | Reemplazos modernos para `cd`, `ls`, `cat` y búsqueda interactiva |
| **Paquetes** | [Scoop](https://scoop.sh/) / [Homebrew](https://brew.sh/) | Instalación sin privilegios en Windows y Linux; winget queda solo para lo que integra con el sistema (Git, PowerShell, rustup). La config de Scoop la aplica el provisioner, no a mano |
| **Runtimes** | [mise](https://mise.jdx.dev/) / [rustup](https://rustup.rs/) | mise posee node, pnpm, go, uv, gh y bun desde un solo archivo; rustup posee cargo y rustc. **`mise self-update` no se usa**: mise lo instaló Scoop, así que se actualiza con `scoop update mise` |

---

## 🧭 Portabilidad

Reglas que el repo cumple hoy, para no reintroducir los mismos bugs:

- Toda ruta sale de `.chezmoi.homeDir`: no hay literales `/home/<usuario>` ni `C:/Users/<nombre>` en los templates.
- El prefix de Homebrew se define una sola vez en `.chezmoidata.toml` y se consume vía `.chezmoitemplates/brew-path.tmpl`.
- La clave de firma SSH se resuelve una sola vez en `.chezmoitemplates/git-signing-key.tmpl` (`id_ed25519` > `id_rsa` > `.git.signingkey` > vacío) y `commit.gpgsign` se desactiva cuando no hay clave, así una máquina nueva puede commitear igual.
- Las herramientas que pueden faltar (`delta`, `code`, `nvim`) están gateadas con `lookPath`.
- Windows Terminal se trackea con `"commandline": "nu.exe"` (resuelve por PATH vía el shim de Scoop) en lugar de la ruta absoluta `C:/Users/<usuario>/scoop/apps/nu/current/nu.exe`, y `AppData/**` se ignora fuera de Windows.
- `run_once_after_set-xdg` fija además `GH_CONFIG_DIR` en `%APPDATA%\GitHub CLI`: `gh` prefiere `$XDG_CONFIG_HOME` si existe y ahí no tiene sus credenciales, así que sin esa variable responde «not logged in» con XDG activo. Se resuelve por variable de usuario y no por perfil, para cubrir PowerShell, nushell y Git Bash a la vez.
- La config de Scoop vive en el provisioner, nunca en `~/.config/scoop/config.json` editado a mano (Scoop reescribe ese archivo en cada `update`): `autostash_on_conflict` (que solo afecta el update del repo de Scoop, no los buckets), `cat_style plain`, `show_update_log false` y `aria2-warning-enabled false`, todos idempotentes. La clave que Scoop lee es `aria2-warning-enabled` **sin `c`**; `aria2c-warning-enabled` es inerte y el script la borra. `use_sqlite_cache` se activa recién después del `scoop import`, porque encenderlo dispara una descarga de SQLite dentro de `add_bucket` y una caída de red ahí abortaría la instalación de las apps.
- Los runtimes de mise se actualizan con `mise up` (respeta `minimum_release_age`, 24 h por defecto), y mise en sí con `scoop update mise`, porque Scoop es su dueño en Windows.
- Los paquetes de Windows se declaran en **dos archivos con dueños distintos**: `scoopfile.json` (toolchain que necesita cualquier máquina) y `scoopfile.apps.json` (apps de escritorio del dueño del repo). El provisioner los importa en ese orden y el segundo es opcional, así una máquina que solo necesita las herramientas de desarrollo no arrastra las apps de escritorio.
- Aplica exactamente un provisioner por OS.
- `.chezmoiversion` fija la versión mínima de chezmoi (2.74.0).

---

## 🚀 Quickstart (Nueva Máquina)

El proceso de inicialización clona el repositorio, solicita interactivamente tu identidad de Git (`user.name`, `user.email`) y detecta tu clave SSH (`id_ed25519.pub`) para firma de commits.

### 🪟 Windows (PowerShell 7+)

```powershell
pwsh -c "& { iex (iwr 'https://get.chezmoi.io') } ; chezmoi init --apply Row0902/row.dots"
```

> **Aprovisionamiento automático (dos fases):**
> `chezmoi apply` ejecuta primero `run_once_before_install-packages.ps1`, que instala con Scoop las CLI portables (starship, eza, bat, fd, ripgrep, fzf, zoxide, delta, lazygit, direnv, nu y mise) y con winget lo que integra con el sistema (Git for Windows, PowerShell 7 y rustup). Después, `run_once_after_install-runtimes.ps1` hace que mise instale node, pnpm, go, uv, gh y bun desde `dot_config/mise/config.toml`.
>
> **Bootstrap opcional y manual (Scoop + ssh-agent):**  
> Si preferís el catálogo de Scoop y querés configurar el servicio `ssh-agent`:
> ```powershell
> pwsh ~/.local/share/chezmoi/scripts/bootstrap.ps1
> ```

---

### 🐧 Linux / macOS

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply Row0902/row.dots
```

> **Aprovisionamiento automático (dos fases):**
> `chezmoi apply` ejecuta primero `run_once_before_install-homebrew.sh`, que instala las dependencias de compilación del sistema, Homebrew (con `NONINTERACTIVE=1`, para que no se quede esperando confirmación por `/dev/tty`), corre `brew update && brew upgrade`, da de alta los taps con su `brew trust`, aplica `brew bundle` y registra fish y nu en `/etc/shells` para dejar fish como shell por defecto. Después, `run_once_after_install-runtimes.sh` hace que mise instale node, pnpm, go, uv, gh y bun desde `dot_config/mise/config.toml`.
>
> Rust no entra en ninguna de las dos fases: rustup gobierna cargo y rustc, y el toolchain es una decisión de máquina (`rustup default stable`).

> **Bootstrap opcional (Homebrew + bundle):**  
> Para instalar dependencias del sistema, cambiar la shell por defecto a Fish y autenticar GitHub CLI:
> ```bash
> ~/.local/share/chezmoi/scripts/bootstrap.sh
> ```

---

## 🎨 Anatomía del Prompt (Starship)

El prompt utiliza un esquema *Powerline Pill* de dos líneas con paleta Tokyo Night, glifos Nerd Fonts y adaptación contextual del sistema operativo:

```text
[ 󰖳 ]  [ ~/workspaces/apa7 ]  [  main ]  [ 󱃾 loaded  󱔎 3.12 ] ───────── [ ⏱ 1.2s ] [  19:45 ]
❯ 
```

- **Píldora 1 (OS):** Glifo adaptativo según el entorno (`󰖳` Windows, `` Arch, `` Fedora, `` Ubuntu/Debian, `` macOS).
- **Píldora 2 (Directorio):** Truncado a 3 niveles con iconos semánticos para carpetas conocidas (`Documents`, `Downloads`, etc.).
- **Píldora 3 (Git):** Rama activa (``) e indicador de estado adelantado/retrasado (`ahead/behind`).
- **Píldora 4 (Runtimes):** Se activan **únicamente** si el proyecto actual los utiliza:
  - 🥟 Bun •  Node.js • 󱔎 Python (con venv activo) • 󱘗 Rust •  Go • 󱃾 direnv
- **Alineación derecha:** Tiempo de ejecución del comando (si excede 1s) y reloj digital.
- **Línea de comando:** Carácter `❯` en azul (`#769ff0`), con cambio automático a rojo (`#f7768e`) si el último comando terminó con error.

---

## 🛠️ Flujo de Trabajo Diario

Chezmoi opera como una capa intermedia entre tu repositorio local y el sistema de archivos:

| Acción | Comando | Descripción |
| :--- | :--- | :--- |
| **Auditar diferencias** | `chezmoi diff` | Compara el estado deseado contra tus archivos actuales sin tocar nada |
| **Aplicar cambios** | `chezmoi apply` | Sincroniza las plantillas y aplica los archivos en tu `$HOME` |
| **Editar configuración** | `chezmoi edit ~/.gitconfig` | Abre la plantilla fuente (`.tmpl`) en tu editor preferido |
| **Actualizar desde GitHub** | `chezmoi update` | Hace `git pull` de `row.dots` y aplica las actualizaciones |
| **Ver estado** | `chezmoi status` | Lista los archivos gestionados que difieren del repositorio |

---

## 🔒 Identidad Local y Seguridad

Para evitar exponer información privada en repositorios públicos:

1. **Configuración local (`~/.gitconfig.local`):**  
   Este archivo es generado automáticamente en cada máquina y **no está trackeado en el repositorio**. Contiene tu nombre, correo y firma SSH:
   ```ini
   [user]
       name = Rowell Urbaez Reyes
       email = 167712855+Row0902@users.noreply.github.com
       signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
   ```

2. **Ajustes de máquina (`~/.config/chezmoi/chezmoi.toml`):**  
   Almacena las variables específicas de cada host para la evaluación de templates.

---

## 📂 Estructura del Repositorio

```text
row.dots/
├── .chezmoiignore                       # Exclusiones por OS (fish solo en Linux, AppData solo en Windows, un provisioner por OS)
├── AppData/                             # Solo Windows: estado de apps empaquetadas (MSIX)
│   └── Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json
├── .chezmoidata.toml                    # Datos globales: prefix de Homebrew, editor, rama por defecto
├── .chezmoi.toml.tmpl                   # Asistente de configuración para primer inicio
├── .chezmoiversion                      # Versión mínima de chezmoi (2.74.0)
├── .chezmoitemplates/                   # Partials compartidos entre templates
│   ├── brew-path.tmpl                   # PATH de Homebrew resuelto desde .chezmoidata.toml
│   └── git-signing-key.tmpl             # Clave de firma SSH (fuente única)
├── dot_config/
│   ├── direnv/                          # Configuración y layouts para Python uv/venv
│   ├── fish/                            # Solo Linux (ver nota de plataformas)
│   │   ├── config.fish                  # Configuración base de Fish
│   │   ├── conf.d/                      # Snippets, incluido 00-path.fish.tmpl
│   │   ├── functions/                   # Funciones propias (cdl, mkcd, extract…)
│   │   └── completions/                 # Completions propias
│   ├── mise/                            # config.toml: node, pnpm, go, uv, gh, bun
│   ├── nushell/                         # config.nu + autoloads (starship, direnv, zoxide)
│   ├── powershell/                      # Cuerpo del perfil de PowerShell 7
│   └── starship.toml.tmpl               # Prompt con badge dinámico de OS
├── dot_gitconfig.tmpl                   # Git: Delta, rebase, firma SSH, credential manager
├── dot_gitconfig.local.tmpl             # Identidad y clave detectadas en cada máquina
├── dot_gitignore_global                 # Exclusión global (Zone.Identifier, etc.)
├── run_once_before_install-homebrew.sh.tmpl   # Provisioner Linux/macOS (Homebrew + Brewfile)
├── run_once_after_install-runtimes.sh.tmpl    # Linux/macOS: mise instala los runtimes
├── run_once_before_install-packages.ps1.tmpl  # Provisioner Windows (Scoop + winget)
├── run_once_after_set-xdg.ps1.tmpl             # Windows: XDG_CONFIG_HOME para nushell
├── run_once_after_install-runtimes.ps1.tmpl    # Windows: mise instala los runtimes
├── run_onchange_after_copy-powershell-profiles.ps1.tmpl  # Copia el perfil a Documents
├── Brewfile                             # Catálogo de paquetes de Homebrew
├── scoopfile.json                       # Tools que necesita todo equipo (importado primero)
├── scoopfile.apps.json                  # Apps de escritorio del dueño del repo (importado después, opcional)
├── LICENSE                              # MIT
├── README.md
├── odd/                                 # Registros de decisión — nunca se aplican a $HOME
└── scripts/
    ├── bootstrap.ps1                    # Opcional en Windows (Scoop + ssh-agent)
    └── bootstrap.sh                     # Bootstrap interactivo Linux/macOS
```

> **Nota de plataformas:** `.chezmoiignore` excluye `dot_config/fish/**` en cualquier SO que no sea Linux, y `AppData/**` en cualquier SO que no sea Windows. En Windows aplican nushell, direnv, starship, la configuración de Git, el perfil de PowerShell y Windows Terminal; nushell lee `~/.config/nushell` porque `run_once_after_set-xdg` fija `XDG_CONFIG_HOME` en el usuario (su data-dir sigue en `%APPDATA%`).

> **Windows Terminal:** `AppData/…/LocalState/settings.json` es un target plano, no un template. El único dato de máquina que tenía era el `commandline` del perfil NuShell, con la ruta absoluta `C:\\Users\\<usuario>\\scoop\\apps\\nu\\current\\nu.exe`; quedó como `nu.exe`, que resuelve por PATH vía el shim de Scoop. Dos cuidados: (1) **cerrá WT antes de cada `chezmoi apply`**, porque WT reescribe el archivo al salir y puede revertir lo aplicado; (2) el package family `Microsoft.WindowsTerminal_8wekyb3d8bbwe` es el de la versión de Store — con WT unpackaged o Preview la ruta es otra y hay que mover el target.

---

<div align="center">
  <sub>Construido con precisión para desarrollo diario. Licencia MIT.</sub>
</div>
