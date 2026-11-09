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
| **Paquetes** | [Scoop](https://scoop.sh/) / [Homebrew](https://brew.sh/) | Instalación sin privilegios de administrador en Windows y Linux |

---

## 🚀 Quickstart (Nueva Máquina)

El proceso de inicialización clona el repositorio, solicita interactivamente tu identidad de Git (`user.name`, `user.email`) y detecta tu clave SSH (`id_ed25519.pub`) para firma de commits.

### 🪟 Windows (PowerShell 7+)

```powershell
pwsh -c "& { iex (iwr 'https://get.chezmoi.io') } ; chezmoi init --apply Row0902/row.dots"
```

> **Bootstrap opcional (Scoop + herramientas CLI):**  
> Si querés instalar automáticamente todo el catálogo de herramientas y configurar el servicio `ssh-agent`:
> ```powershell
> pwsh ~/.local/share/chezmoi/scripts/bootstrap.ps1
> ```

---

### 🐧 Linux / macOS

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply Row0902/row.dots
```

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
├── .chezmoiignore          # Reglas de exclusión por OS (evita scripts/archivos cruzados)
├── .chezmoidata.toml       # Variables globales de entorno y herramientas
├── .chezmoi.toml.tmpl      # Asistente de configuración para primer inicio
├── dot_config/
│   ├── direnv/             # Configuración y layouts para Python uv/venv
│   ├── fish/               # Configuración, alias y funciones de Fish shell
│   ├── nushell/            # Autoloads de Starship y direnv para Nushell
│   └── starship.toml.tmpl  # Plantilla del prompt con badge dinámico de OS
├── dot_gitconfig.tmpl      # Configuración de Git (Delta, rebase, SSH signing, credential manager)
├── dot_gitconfig.local.tmpl# Detección automática de identidad y claves ed25519/rsa
├── dot_gitignore_global    # Reglas globales de exclusión (Zone.Identifier, etc.)
└── scripts/
    ├── bootstrap.ps1       # Aprovisionamiento interactivo para Windows (Scoop)
    └── bootstrap.sh        # Aprovisionamiento interactivo para Linux/macOS (Brew)
```

---

<div align="center">
  <sub>Construido con precisión para desarrollo diario. Licencia MIT.</sub>
</div>
