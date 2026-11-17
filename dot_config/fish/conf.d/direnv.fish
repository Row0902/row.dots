if type -q direnv
    direnv hook fish | source
    abbr -g dv direnv
end
