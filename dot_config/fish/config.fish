if status is-interactive
    # Suprimir el mensaje de bienvenida de Fish
    set -g fish_greeting ""
    # Límite de entradas en el historial
    set -g fish_history_max_entries 20000
end
