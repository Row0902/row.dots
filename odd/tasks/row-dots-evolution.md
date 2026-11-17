# row.dots — evolución del repo chezmoi

Dotfiles gestionados con chezmoi v2.74.0 (Windows 11 + Linux). Repo: `Row0902/row.dots`.
Objetivo: saneamiento, portabilidad real entre máquinas/usuarios y eliminación de deuda acumulada.

## Specs

- **S1** — «necesito evolucionarlos o mer donde hay puntos de mejoras o que sacar»: auditar el repo, evolucionar lo que corresponda y sacar lo que no aporta.
- **S2** — «investiga la docs de chezmoi a partir de la versión que tengo instalada para que utilices la sintaxis y mejoras más potentes»: toda decisión técnica se valida contra chezmoi v2.74.0 instalado (`execute-template`, `managed`, `apply --dry-run`), no contra documentación genérica ni supuestos.
- **S3** — «que los dots tienen que ser transversal al equipo o usuario»: ningún template puede asumir un usuario, un home, una ruta absoluta ni una herramienta instalada; se resuelve con `.chezmoi.homeDir`, `.chezmoidata.toml`, partials y `lookPath`.
- **S4** — «lo de openspect deberíamos pasarlo a odd y listo porque ya no utilizo sdd o borrarlo simplemente si tienes todo el conocimiento de los dots»: retirar `openspec/` del repo; el historial queda recuperable en git y el conocimiento vigente pasa a este documento ODD.
- **S5** — Verificación obligatoria: ningún task se cierra sin `chezmoi managed`, `chezmoi status` y `chezmoi apply --dry-run` en verde. Los cambios ya aplicados a `$HOME` se confirman con `chezmoi cat`.

## Tasks

- **T1** · S1,S2,S3 · inline · — · Provisioner de Windows reactivado (`.chezmoiignore`), signing key SSH con fuente única (`.chezmoitemplates/git-signing-key.tmpl`), `gpgsign` condicionado, `autoCommit` off, `delta`/`editor` gateados con `lookPath`, `.chezmoiversion`, `config.fish.tmpl` sin rutas de usuario, `win_keys` en `bootstrap.sh`, `.atl/skill-registry.md` destrackeado. **Hecho.**
- **T2** · S1,S2,S3 · inline · — · Colapsar los 9 bloques de PATH de Homebrew duplicados en `dot_config/fish/conf.d/*.fish` a un único `00-path.fish` alimentado por `.chezmoitemplates/brew-path.tmpl`; eliminar las variables basura `*_PATH` que hoy se exportan al entorno. **Hecho** (`00-path.fish.tmpl`, 10 archivos reducidos a su guard `type -q`).
- **T3** · S1 · inline · — · Borrar archivos muertos: `conf.d/fish_frozen_key_bindings.fish` (fish pide borrarlo), `functions/fish_prompt.fish` (lo pisa starship), `nushell/env.nu` (solo comentarios), `completions/bun.fish` (vendorizado y roto), `conf.d/docker.fish` (docker no está provisionado). **Hecho** salvo `docker.fish`, que se conservó reducido a su guard `type -q docker`: sus abreviaturas son funcionalidad del usuario, no ruido de PATH.
- **T4** · S1,S3 · inline · — · Cerrar la brecha config/provisión: `nushell` y `direnv` se aplican en Windows pero no los instala nadie; `neovim` falta en el `Brewfile`. Ids de paquete verificados, no inventados. **Hecho** (`brew neovim`; winget `direnv.direnv` + `Nushell.Nushell`; scoop `neovim` + `direnv` + `nu` — ojo: scoop no tiene `nushell`, el manifiesto es `nu`).
- **T5** · S3 · inline · — · `nushell/config.nu`: `$env.USER` no existe en Windows → hook de prompt falla. Resolver con fallback a `USERNAME`. **Hecho** (y `$env.HOME` → `$nu.home-dir`; `nu -c 'source …'` → PARSE-OK).
- **T6** · S4 · inline · — · Borrar `openspec/` (457K, ~90 docs de SDD discontinuado) y dejar este documento como fuente de verdad. Eliminar la regla `openspec/**` del `.chezmoiignore`. **Hecho** (73 archivos; se agregaron `odd/**` y `LICENSE` al ignore para que no aterricen en `$HOME`).
- **T7** · S1 · inline · — · Corregir drift factual del `README.md`: badge de LICENSE sin LICENSE, `dot_gitignore_global` vs `.tmpl`, árbol de estructura incompleto, Scoop vs winget. **Hecho** + `LICENSE` MIT creado (visible el badge sin archivo).
- **T8** · S5 · verify · — · Verificación final: `managed`, `status`, `apply --dry-run`, renders de cada template tocado.

## Log

- **Verificación T8** — `chezmoi managed` = 14 (15 menos `nushell/env.nu`, borrado en T3) · `chezmoi status` = solo `R install-packages.ps1` · `chezmoi apply --dry-run` exit 0 sin salida · verificación independiente: 6 PASS y 1 FAIL corregido (el README afirmaba que fish aplica en macOS; `.chezmoiignore` lo excluye en todo lo que no sea Linux) · `nu -c 'source dot_config/nushell/config.nu'` PARSE-OK.
- **No verificable en este host** — la sintaxis de fish (no hay `fish` instalado en Windows) y los ids de paquete solo se validaron contra catálogo, sin instalar. Confirmar en Linux con `fish -n ~/.config/fish/**/*.fish` tras el primer `apply`.
- **Pendiente de decisión** — el próximo `chezmoi apply` completo corre el provisioner de winget por primera vez (11 paquetes). Aplicar solo archivos con `chezmoi apply --include=files`.
- **L1** — «Sabes que mis dots los manejo a través de chezmoi que también está instalado, necesito evolucionarlos o mer donde hay puntos de mejoras o que sacar»
- **L2** — «Haz el saniamiento pero investiga la docs de chezmoi a partir de la versión que tengo instalada para que utilices la sintaxis y mejoras más potentes y que los dots tienen que ser transversal al equipo o usuario»
- **L3** — «dale con la segunda tanda, aunque lo de openspect deberíamos pasarlo a odd y listo porque ya no utilizo sdd o borrarlo simplemente si tienes todo el conocimiento de los dots»
- **Decisión (agente, L3)** — openspec se **borra**, no se migra: son ~90 documentos de cambios ya completados, el estado vigente vive en los templates y el historial completo sigue en git (`git log -- openspec/`). El documento que estás leyendo reemplaza lo único que aportaban: la razón de cada decisión.
- **Hallazgo (verificado con el binario)** — `.chezmoi.toml.tmpl` no ve `.chezmoidata.toml`; `.chezmoiignore` matchea target paths y admite negación `!`; `includeTemplate "x"` sin path busca en la raíz del source (falla); un `{{/* … */}}` con `}}` adentro rompe el parser.
