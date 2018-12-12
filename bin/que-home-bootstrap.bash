#!/usr/bin/env bash

: ${STRAP_URL:=https://raw.github.com/alerque/que/master}

function fail () {
    echo "$@" >&2
    exit 1
}

# Error out of script if _anything_ goes wrong
set -e

# This is meant to be a user space utility, bail if we are root
test $UID -eq 0 && fail "Don't be root!"
cd $HOME

# If we don't have these tools, we should be running que-sys-bootstrap.bash instead
which git mr curl ssh-agent vcsh > /dev/null ||
    fail "Necessary tools not available, run que-sys-bootstrap.bash as root instead.\n\nbash <(curl -s -L $STRAP_URL/bin/que-sys-bootstrap.bash)"

# If everything isn't just right with SSH keys and config for the next step, manually fetch them
test -d .ssh || mkdir .ssh ; chmod 750 .ssh
(umask 177
	test -f .ssh/id_rsa -a -f .ssh/github && grep -q github .ssh/config || (
        curl --request GET --header "Private-Token: $(read -s -p 'Gitlab Private-Token: ' && echo $REPLY)" \
            -o .ssh/gitlab      'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fgitlab' \
            -o .ssh/known_hosts 'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fknown_hosts' \
            -o .ssh/config      'https://gitlab.alerque.com/caleb/que-secure/raw/master/.ssh%2Fconfig'
	)
    grep -q github.com .ssh/config ||
        fail "Invalid creds, got garbage files"
)

eval $(ssh-agent)
ssh-add .ssh/gitlab

# Rename repository if it exists under old name
test -d .config/vcsh/repo.d/caleb-private.git &&
    mv .config/vcsh/repo.d/{caleb-private,que-secure}.git

# mr would clone this, but it needs this to clone other things and this needs manual care on first setup
test -d .config/vcsh/repo.d/que-secure.git &&
    vcsh que-secure pull ||
    vcsh clone gitlab@gitlab.alerque.com:caleb/que-secure.git que-secure
chmod 600 .ssh/{config,authorized_keys} $(grep 'PRIVATE KEY' -Rl .ssh)

ssh-add .ssh/id_rsa
ssh-add .ssh/github
ssh-add .ssh/aur

grep -q 'hook pre-merge' $(which vcsh) ||
    fail "VCSH version too old, does not have required pre-merge hook system"

# Get or update man repo that has mr configs
test -d .config/vcsh/repo.d/que.git &&
    vcsh que pull ||
    vcsh clone git@github.com:alerque/que.git que

# checkout everything else
mr co
