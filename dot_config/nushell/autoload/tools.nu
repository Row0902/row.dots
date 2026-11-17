# Atajos de las herramientas modernas, para que nushell tenga la misma caja de
# herramientas que fish.
#
# Deliberadamente NO se redefinen `ls` ni `cat`: en nushell son comandos que
# devuelven datos estructurados y los usan los pipelines. `ls -l foo | where
# size > 1kb` deja de funcionar si `ls` pasa a ser eza.
if (which eza | is-not-empty) {
    alias ll = eza -la --icons --group-directories-first
    alias lt = eza --tree --level=2 --icons
}

if (which lazygit | is-not-empty) {
    alias lg = lazygit
}
