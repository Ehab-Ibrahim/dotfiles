function gl --wraps='git log --oneline --graph --color --exclude=refs/stash --all --decorate' --description 'alias gl=git log --oneline --graph --color --exclude=refs/stash --all --decorate'
  git log --oneline --graph --color --exclude=refs/stash --all --decorate $argv; 
end
