if status is-interactive
  # Add some common paths
  fish_add_path -g ~/bin/
  fish_add_path -g ~/.local/bin/

  set -l agent_sock $HOME/.ssh/agent.sock
  if test -S $agent_sock
    set -x SSH_AUTH_SOCK $agent_sock
  end

  # Add mise tools
  fish_add_path -g (mise bin-paths)
  # Fallback for tools installed after this shell started
  fish_add_path -g -a ~/.local/share/mise/shims

  # Add completions shipped inside the mise release archives
  set -l installs ~/.local/share/mise/installs
  for dir in $installs/*/latest/{,*/}{complete,completions,autocomplete,contrib/completion}/
    set -g fish_complete_path $dir $fish_complete_path
  end

  fzf_configure_bindings --directory=\co
  if command -q starship
    starship init fish | source
  end
  if command -q zoxide
    zoxide init fish | source
  end
  if command -q eza
    alias eza 'eza --icons auto --color auto --git --header --group'
    alias la 'eza -a'
    alias ll 'eza -l'
    alias lla 'eza -la'
    alias ls eza
    alias lt 'eza --tree'
  end

  if command -q direnv
    # Hook direnv to shell
    if set -q DIRENV_DIR && begin; set -q ZELLIJ || set -q NVIM; end
      set -e (set -n | grep DIRENV_)
    end
    direnv hook fish | source
  end
end
