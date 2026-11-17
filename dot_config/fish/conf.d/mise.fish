# mise — runtimes y versiones por proyecto.
# Su config vive en dot_config/mise/config.toml (node, pnpm, go, uv, gh, bun).
if type -q mise
    mise activate fish | source
end
