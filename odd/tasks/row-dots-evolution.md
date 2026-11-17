# row.dots — evolución del repo chezmoi

Dotfiles gestionados con chezmoi v2.74.0 (Windows 11 + Linux). Repo: `Row0902/row.dots`.
Objetivo: saneamiento, portabilidad real entre máquinas/usuarios y eliminación de deuda acumulada.

## Specs

- **S1** — «necesito evolucionarlos o mer donde hay puntos de mejoras o que sacar»: auditar el repo, evolucionar lo que corresponda y sacar lo que no aporta.
- **S2** — «investiga la docs de chezmoi a partir de la versión que tengo instalada para que utilices la sintaxis y mejoras más potentes»: toda decisión técnica se valida contra chezmoi v2.74.0 instalado (`execute-template`, `managed`, `apply --dry-run`), no contra documentación genérica ni supuestos.
- **S3** — «que los dots tienen que ser transversal al equipo o usuario»: ningún template puede asumir un usuario, un home, una ruta absoluta ni una herramienta instalada; se resuelve con `.chezmoi.homeDir`, `.chezmoidata.toml`, partials y `lookPath`.
- **S4** — «lo de openspect deberíamos pasarlo a odd y listo porque ya no utilizo sdd o borrarlo simplemente si tienes todo el conocimiento de los dots»: retirar `openspec/` del repo; el historial queda recuperable en git y el conocimiento vigente pasa a este documento ODD.
- **S5** — Verificación obligatoria: ningún task se cierra sin `chezmoi managed`, `chezmoi status` y `chezmoi apply --dry-run` en verde. Los cambios ya aplicados a `$HOME` se confirman con `chezmoi cat`.
- **S6** — «los paquetes que se instalan los vamos a pasar a scoop no winget a exepción de los que sean más viable integrarlo por winget»: en Windows la vía por defecto es Scoop; winget queda reservado para lo que integra con el sistema operativo (instalador MSI, PATH de sistema, Credential Manager, OpenSSH). Un solo dueño por lista de paquetes: el `run_once` provisiona, el bootstrap solo hace lo interactivo.

## Tasks

- **T1** · S1,S2,S3 · inline · 95a930d · Provisioner de Windows reactivado (`.chezmoiignore`), signing key SSH con fuente única (`.chezmoitemplates/git-signing-key.tmpl`), `gpgsign` condicionado, `autoCommit` off, `delta`/`editor` gateados con `lookPath`, `.chezmoiversion`, `config.fish.tmpl` sin rutas de usuario, `win_keys` en `bootstrap.sh`, `.atl/skill-registry.md` destrackeado. **Hecho.**
- **T2** · S1,S2,S3 · inline · 0071951 · Colapsar los 9 bloques de PATH de Homebrew duplicados en `dot_config/fish/conf.d/*.fish` a un único `00-path.fish` alimentado por `.chezmoitemplates/brew-path.tmpl`; eliminar las variables basura `*_PATH` que hoy se exportan al entorno. **Hecho** (`00-path.fish.tmpl`, 10 archivos reducidos a su guard `type -q`).
- **T3** · S1 · inline · 0071951 + 36f427f · Borrar archivos muertos: `conf.d/fish_frozen_key_bindings.fish` (fish pide borrarlo), `functions/fish_prompt.fish` (lo pisa starship), `nushell/env.nu` (solo comentarios), `completions/bun.fish` (vendorizado y roto), `conf.d/docker.fish` (docker no está provisionado). **Hecho** salvo `docker.fish`, que se conservó reducido a su guard `type -q docker`: sus abreviaturas son funcionalidad del usuario, no ruido de PATH.
- **T4** · S1,S3 · inline · 61086d8 · Cerrar la brecha config/provisión: `nushell` y `direnv` se aplican en Windows pero no los instala nadie; `neovim` falta en el `Brewfile`. Ids de paquete verificados, no inventados. **Hecho** (`brew neovim`; winget `direnv.direnv` + `Nushell.Nushell`; scoop `neovim` + `direnv` + `nu` — ojo: scoop no tiene `nushell`, el manifiesto es `nu`).
- **T5** · S3 · inline · 36f427f · `nushell/config.nu`: `$env.USER` no existe en Windows → hook de prompt falla. Resolver con fallback a `USERNAME`. **Hecho** (y `$env.HOME` → `$nu.home-dir`; `nu -c 'source …'` → PARSE-OK).
- **T6** · S4 · inline · 869feb6 · Borrar `openspec/` (457K, ~90 docs de SDD discontinuado) y dejar este documento como fuente de verdad. Eliminar la regla `openspec/**` del `.chezmoiignore`. **Hecho** (73 archivos; se agregaron `odd/**` y `LICENSE` al ignore para que no aterricen en `$HOME`).
- **T7** · S1 · inline · 869feb6 · Corregir drift factual del `README.md`: badge de LICENSE sin LICENSE, `dot_gitignore_global` vs `.tmpl`, árbol de estructura incompleto, Scoop vs winget. **Hecho** + `LICENSE` MIT creado (visible el badge sin archivo).
- **T8** · S5 · verify · sin commit (verificación) · Verificación final: `managed`, `status`, `apply --dry-run`, renders de cada template tocado.
- **T9** · S3,S6 · inline · — · Provisioner Windows scoop-first: el `run_once` instala Scoop + bucket `main` + la lista portable; winget queda solo con `Git.Git` (Credential Manager y OpenSSH de sistema) y `Microsoft.PowerShell` (MSI con PATH de sistema).
- **T10** · S1,S3 · inline · — · `bootstrap.ps1` deja de duplicar la lista de paquetes y de escribir `~/.gitconfig.local` (propiedad de chezmoi); queda solo con lo interactivo: ssh-agent, `gh auth login`, remote a SSH.
- **T11** · S1,S3 · inline · — · `bootstrap.sh` deja de escribir `~/.gitconfig.local` y de duplicar `brew bundle`; la identidad y la signing key SSH las resuelve chezmoi. Los prompts «GPG» desaparecen con esa fase.
- **T12** · S5,S6 · verify · — · Verificar: un solo dueño por lista de paquetes, render de los 4 scripts, ningún script escribe archivos gestionados por chezmoi, `chezmoi apply --dry-run`.
- **T13** · S3,S7 · inline · — · Cablear zoxide en el autoload gestionado de nushell (`autoload/zoxide.nu`) **antes** de mover el config dir, y verificar que `autoload/direnv.nu` funciona en nu 0.116 (`env-conversions` de std).
- **T14** · S3,S7,S8 · inline · — · `run_once_after_set-xdg.ps1.tmpl`: setea `XDG_CONFIG_HOME` a `%USERPROFILE%\.config` en scope User, idempotente. Verificar que `nu` pasa a leer `~/.config/nushell` y que el data-dir (historial, plugin, vendor) sigue en `%APPDATA%`.
- **T15** · S7,S8 · inline · — · Perfiles de PowerShell: cuerpo en `dot_config/powershell/profile.ps1` + `run_onchange_after_copy-powershell-profiles.ps1.tmpl` que resuelve `Documents` con `GetFolderPath('MyDocuments')`. Borrar la regla muerta `Documents/PowerShell/**` del ignore.
- **T16** · S7 · inline · — · Borrar restos de la migración: `~/.config/nushell/env.nu`, `~/.config/chezmoi/chezmoi.toml.bak-*`, el config previo `AppData/Roaming/nushell/config.nu` y `~/.zoxide.nu`, cada uno después de que su reemplazo esté verificado.
- **T17** · S3,S7 · inline · — · Portabilidad real de los targets de Windows: `direnvrc` con rama por OS (`.venv/Scripts`), `filemode` solo fuera de Windows, quitar `[protocol] version = 2`.
- **T18** · S1,S7 · inline · — · Limpieza del repo: claves muertas de `.chezmoidata.toml`, borrar `os-path.tmpl` y `git-identity.tmpl`, `dot_gitignore_global.tmpl` → sin `.tmpl`, y corregir el README (provisioner scoop/winget, árbol real).
- **T19** · S5,S7 · verify · — · Verificación final de Windows: `chezmoi managed`/`status`/`apply --dry-run`, `nu` leyendo el config gestionado, perfiles copiados, sin restos, y render de cada template tocado.

- **S7** — «antes puliremos windows completo que es mi sistema operativo principal»: Windows es el SO principal y tiene que quedar coherente antes de validar la rama Linux en Fedora WSL. Un archivo aplicado que nadie lee, o un config leído que no está en el repo, es deuda.
- **S8** — Decisiones de S7: nushell se unifica con `XDG_CONFIG_HOME` seteado desde el repo (User scope, vía `run_once`), y los perfiles de PowerShell se incorporan por copia `run_onchange` a `Documents` (sin symlinks, que requieren elevación y no cruzan de C: a D:).

## Log

- **Verificación T8** — `chezmoi managed` = 14 (15 menos `nushell/env.nu`, borrado en T3) · `chezmoi status` = solo `R install-packages.ps1` · `chezmoi apply --dry-run` exit 0 sin salida · verificación independiente: 6 PASS y 1 FAIL corregido (el README afirmaba que fish aplica en macOS; `.chezmoiignore` lo excluye en todo lo que no sea Linux) · `nu -c 'source dot_config/nushell/config.nu'` PARSE-OK.
- **No verificable en este host** — la sintaxis de fish (no hay `fish` instalado en Windows) y los ids de paquete solo se validaron contra catálogo, sin instalar. Confirmar en Linux con `fish -n ~/.config/fish/**/*.fish` tras el primer `apply`.
- **Pendiente de decisión** — el próximo `chezmoi apply` completo corre el provisioner de winget por primera vez (11 paquetes). Aplicar solo archivos con `chezmoi apply --include=files`.
- **L1** — «Sabes que mis dots los manejo a través de chezmoi que también está instalado, necesito evolucionarlos o mer donde hay puntos de mejoras o que sacar»
- **L2** — «Haz el saniamiento pero investiga la docs de chezmoi a partir de la versión que tengo instalada para que utilices la sintaxis y mejoras más potentes y que los dots tienen que ser transversal al equipo o usuario»
- **L3** — «dale con la segunda tanda, aunque lo de openspect deberíamos pasarlo a odd y listo porque ya no utilizo sdd o borrarlo simplemente si tienes todo el conocimiento de los dots»
- **L4** — «USí, commitea, pushea y pr»
- **Entrega (L4)** — un solo PR (#29) sobre `main`, rama `chore/dots-portability`, 6 commits por unidad de trabajo. El conteo de 6.852 líneas es engañoso: son ~130 líneas escritas nuevas en 27 archivos; el resto es el borrado de 73 documentos archivados de `openspec/`, que no se revisan línea por línea. El repo no tiene `.github/`: sin template de PR, sin CI y sin labels que cumplir, y `shellcheck` no está instalado en la máquina Windows.
- **Decisión (agente, L3)** — openspec se **borra**, no se migra: son ~90 documentos de cambios ya completados, el estado vigente vive en los templates y el historial completo sigue en git (`git log -- openspec/`). El documento que estás leyendo reemplaza lo único que aportaban: la razón de cada decisión.
- **Hallazgo (verificado con el binario)** — `.chezmoi.toml.tmpl` no ve `.chezmoidata.toml`; `.chezmoiignore` matchea target paths y admite negación `!`; `includeTemplate "x"` sin path busca en la raíz del source (falla); un `{{/* … */}}` con `}}` adentro rompe el parser.
