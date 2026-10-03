export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/cpython"
mkdir -p $PYTHONPYCACHEPREFIX

if ! command -v pyenv &> /dev/null; then
    curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="/home/patrick/.local/share/pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
eval "$(pyenv virtualenv-init -)"
