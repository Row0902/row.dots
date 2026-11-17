# config.nu
#
# Instalado por chezmoi (row.dots). Se sobreescribe: editá la fuente en
# dot_config/nushell/config.nu, no este archivo.
#
# Portabilidad: en Windows `$env.USER` y `$env.HOME` no siempre existen,
# por eso el usuario sale de USER/USERNAME y el home de $nu.home-dir.

$env.config = {

    show_banner: false

    hooks: {
        pre_prompt: [{ ||
            let base_name = ($env.USER? | default ($env.USERNAME? | default "user"))
            let current_dir = (pwd | path basename)
            let title = if (($env.PWD | path expand) == $nu.home-dir) {
                $base_name
            } else {
                $"($base_name):($current_dir)"
            }
            print -n $"(ansi title)($title)(ansi string_terminator)"
        }]
    }
}
