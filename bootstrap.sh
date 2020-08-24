#!/usr/bin/env bash -e

is_testing() {
    [[ -n "${TESTING}" ]]
}

log() {
    echo "bootstrap.sh: $@" 1>&2
}

here() {
    cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd
}

home() {
    if is_testing; then
	echo "$(here)/tmp"
    else
	echo "$HOME"
    fi
}

maybe_clone() {
    if [[ -d "$2" ]]; then
	log "$2 alredy exists"
    else
	git clone "git@github.com:${1}" "$2"
    fi
}

if is_testing; then
    log "[running locally in testing mode]"
    mkdir -p "$(home)"
    chmod -R 600 "$(home)"
else
    log "starting bootstrap [the REAL deal]"
fi

# GPG
export GPG_AGENT_INFO=""
export GNUPGHOME="$(home)/.gnupg"
private_key="$(here)/gpg/private.gpg.asc.asc"
public_key="$(here)/gpg/public.gpg.asc"

echo -n "SECRET: " && read -s secret

log "decrypting private key [$private_key]"
PRIVATE_KEY="$(gpg --batch --passphrase $secret -o- --decrypt $private_key)"

if is_testing; then
    echo "(would run gpg --import)"
else
    echo "$PRIVATE_KEY" | gpg --import
fi

log "importing public key [$public_key]"
if is_testing; then
    echo "(would run gpg --import $public_key)"
else
    gpg --import "$public_key"
fi

# SSH
ssh_key="$(here)/ssh/id_rsa.gpg.asc"
ssh_dir="$(home)/.ssh"
ssh_key_target="$ssh_dir/id_rsa"
log "decrypting private SSH key [$ssh_key]"
SSH_KEY="$(gpg --batch --passphrase $secret -o- --decrypt $ssh_key)"
log "writing SSH key [$ssh_key_target]"
mkdir -p "$ssh_dir"
echo "$SSH_KEY" > "$ssh_key_target"
chmod 600 "$ssh_key_target"

# PASS
GIT_SSH_COMMAND="ssh -i $ssh_key_target -o IdentitiesOnly=yes"
repo_target="$(home)/.password-store"
log "cloning password store [$repo_target]"
maybe_clone "arecker/password-store.git" "$repo_target"

# DOTFILES
mkdir -p "$(home)/src"
dotrepo_target="$(home)/src/dotfiles"
log "cloning dotfiles [$dotrepo_target]"
maybe_clone "arecker/dotfiles.git" "$dotrepo_target"
