if type -q docker
    abbr -g dk docker
    abbr -g dkps 'docker ps'
    abbr -g dksp 'docker system prune'
    abbr -g dkncr 'docker network create'
    abbr -g dknl 'docker network ls'
    abbr -g dknct 'docker network connect'
end
