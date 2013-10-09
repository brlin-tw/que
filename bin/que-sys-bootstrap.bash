#!/bin/bash

# Setup stuff
BASEPACKAGES=(zsh subversion git ctags pcre-tools vim tmux sudo mosh etckeeper ruby-modules zip unzip)
DESKTOPPACKAGES=(awesome dropbox parcellite google-chrome google-talkplugin)

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

function distro_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/$2})
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

# Detect distro
test -f /etc/pld-release && DISTRO=pld
grep -q -s "Ubuntu" /etc/lsb-release && DISTRO=ubuntu
test -f /etc/fedora-release && DISTRO=fedora
#test -f /etc/arch-release && DISTRO=arch
grep -q -s "^Amazon Linux AMI" /etc/system-release && DISTRO=ala

test -n "$DISTRO" || flunk "unrecognized distro"

case $DISTRO in
	ala)
		;;
	pld)
		distro_pkg zsh zsh-completions
		distro_pkg git git-core
		distro_pkg pcre-tools pcregrep
		;;
	ubuntu)
		continue
		;;
	fedora)
		continue
	;;
	*)
		flunk "Distro $DISTRO not yet supported"
		;;
esac

# Make sure we have privs
sudo -n true || flunk "no sudo privs"

# Make sure we have dependencies the init scripts will need

# Check for network access

# Import and run init script for this OS
INITSCRIPT="que-sys-init-${DISTRO}.bash"
if [ -f "$DIR/$INITSCRIPT" ]; then
	source "$DIR/$INITSCRIPT"
else
	source <(curl -s -L https://raw.github.com/alerque/que/master/bin/$INITSCRIPT)
fi

# Setup my user
sudo useradd -s $(which zsh) -m -k /dev/null -G wheel caleb

# If we're on a system with etckeeper, make sure it's setup
if which etckeeper; then
	(
	cd /etc 
	sudo etckeeper vcs status || sudo etckeeper init
	sudo etckeeper commit "End of que-sys-bootstrap.bash run"
	)
fi

# Setup EC2 tools
#openssl-tools xfsprogs ca-certificates-update
#curl http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
