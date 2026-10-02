export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$GOPATH/bin"
[[ -d $GOBIN ]] && export PATH="$GOBIN:$PATH"
