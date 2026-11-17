# Microsoft.PowerShell_profile.ps1 — PowerShell 7 prompt and navigation
#
# Gestionado por chezmoi (row.dots). El archivo real que PowerShell lee vive en
# Documents, que en esta máquina está redirigido a otra unidad, y chezmoi no
# escribe fuera de $HOME: run_onchange_after_copy-powershell-profiles.ps1.tmpl
# copia este cuerpo a la carpeta real de Documents.
#
# Nada acá asume una ruta absoluta: todo se resuelve con Get-Command.
# El orden importa: mise primero (PATH y versiones por proyecto), después
# starship y zoxide, que envuelven el prompt.

# mise — runtimes y versiones por proyecto
if (Get-Command mise -ErrorAction SilentlyContinue) {
    (&mise activate pwsh) | Out-String | Invoke-Expression
}

# Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    (&starship init powershell) | Invoke-Expression
}

# zoxide — cd inteligente: reemplaza cd por la búsqueda de zoxide (z / zi pasan a ser cd / cdi)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (zoxide init powershell --cmd cd | Out-String) | Invoke-Expression
}

# fzf keybindings: fzf has no `--powershell` integration (verified: "unknown
# option: --powershell"). On Windows they come from the PSFzf module, which is
# not provisioned here, so PowerShell gets no Ctrl+T / Alt+C bindings.

# Atajos de las herramientas modernas. No se tocan `ls` ni `cat`: en PowerShell
# son Get-ChildItem y Get-Content, con parámetros que estos reemplazos no tienen.
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Set-Alias -Name ll -Value eza
    function global:lt { eza --tree --level=2 --icons @args }
}

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit
}

# gentle-shell launcher: gs
if (Get-Command gentle-shell -ErrorAction SilentlyContinue) {
    Set-Alias -Name gs -Value gentle-shell
}

# Terminal title: "user" in $HOME, "user:last-folder" elsewhere
function Get-GsTitleName {
    $path = $PWD.Path.TrimEnd('\', '/')
    if ($path -eq $HOME) { return $env:USERNAME }
    $leaf = $path.Substring($path.LastIndexOfAny([char[]]@('\', '/')) + 1)
    if ([string]::IsNullOrEmpty($leaf)) { $leaf = $path }
    "${env:USERNAME}:$leaf"
}

if (-not (Get-Variable __gsPrevPrompt -Scope Global -ErrorAction SilentlyContinue)) {
    $global:__gsPrevPrompt = $function:prompt
    function global:prompt {
        $Host.UI.RawUI.WindowTitle = Get-GsTitleName
        & $global:__gsPrevPrompt
    }
}
