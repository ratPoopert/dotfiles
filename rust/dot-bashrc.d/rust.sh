export CARGO_HOME="$XDG_DATA_HOME/cargo"
[[ -d $CARGO_HOME/bin ]] && export PATH="${CARGO_HOME}/bin:$PATH"
