# Atajos de las herramientas modernas, para que nushell tenga la misma caja de
# herramientas que fish.
#
# Deliberadamente NO se redefinen `ls` ni `cat`: en nushell son comandos que
# devuelven datos estructurados y los usan los pipelines. `ls -l foo | where
# size > 1kb` deja de funcionar si `ls` pasa a ser eza.
#
# Los alias NO van envueltos en `if (which x | is-not-empty) { ... }`: en
# nushell `alias` es una keyword de parseo y queda en el scope del bloque, así
# que un alias declarado dentro de un `if` desaparece al salir del bloque
# (verificado en nu 0.116.1: `if true { alias zz = echo hi }; zz` falla con
# "Command `zz` not found"). Se declaran siempre; si la herramienta no está
# instalada, el error aparece solo al invocarla, igual que con cualquier binario
# ausente.

alias ll = eza -la --icons --group-directories-first
alias lt = eza --tree --level=2 --icons
alias lg = lazygit

# gentle-shell launcher: gs
alias gs = gentle-shell
