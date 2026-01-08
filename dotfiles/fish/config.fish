if status is-interactive
  # Unset CONDA_PREFIX - Needed if fish is installed using pixi
  set -e CONDA_PREFIX

  # Add some common paths
  fish_add_path -g ~/bin/
  fish_add_path -g ~/.local/bin/
  fish_add_path -g ~/.pixi/bin/
  fish_add_path -g ~/npm-modules/bin/

  set -l agent_sock $HOME/.ssh/agent.sock
  if test -S $agent_sock
    set -x SSH_AUTH_SOCK $agent_sock
  end

  # Add pixi global completions
  for file in ~/.pixi/completions/fish/*.fish
    source $file
  end

  fzf_configure_bindings --directory=\co
  {{#if (is_executable "starship")}}
  starship init fish | source
  {{/if}}
  {{#if (is_executable "zoxide")}}
  zoxide init fish | source
  {{/if}}
  {{#if (is_executable "eza")}}
  alias eza 'eza --icons auto --color auto --git --header --group'
  alias la 'eza -a'
  alias ll 'eza -l'
  alias lla 'eza -la'
  alias ls eza
  alias lt 'eza --tree'
  {{/if}}

  {{#if (is_executable "direnv")}}
  # Hook direnv to shell
  if set -q DIRENV_DIR && begin; set -q ZELLIJ || set -q NVIM; end
      set -e (set -n | grep DIRENV_)
  end
  direnv hook fish | source

  {{/if}}
  {{#if (is_executable "uv")}}
  uv generate-shell-completion fish | source
  uvx --generate-shell-completion fish | source

  {{/if}}
end
