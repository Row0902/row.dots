# Microsoft.PowerShell_profile.ps1 — PowerShell 7 prompt and navigation
#
# Gestionado por chezmoi (row.dots). El archivo real que PowerShell lee vive en
# Documents, que en esta máquina está redirigido a otra unidad, y chezmoi no
# escribe fuera de $HOME: run_onchange_after_copy-powershell-profiles.ps1.tmpl
# copia este cuerpo a la carpeta real de Documents.
#
# Nada acá asume una ruta absoluta: todo se resuelve con Get-Command.

# Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    (&starship init powershell) | Invoke-Expression
}

# zoxide — smarter cd (z, zi)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    (zoxide init powershell | Out-String) | Invoke-Expression
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
