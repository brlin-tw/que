#!/bin/bash

ISDESKTOP=0
case $1 in
	desktop)
		ISDESKTOP=1
		shift
		;;
esac

# Setup stuff
BASEPACKAGES=(zsh subversion git ctags pcre-tools vim tmux sudo mosh etckeeper ruby zip unzip mr vcsh wget)
DESKTOPPACKAGES=(awesome dropbox parcellite google-chrome google-talkplugin owncloud-client gnome)
COMPILEBASEPACKAGES=()
COMPILEDESKTOPPACKAGES=()

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

function distro_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/$2})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/$2})
}

function compile_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
	COMPILEBASEPACKAGES=(${COMPILEBASEPACKAGES[@]} $1)
	COMPILEDESKTOPPACKAGES=(${COMPILEDESKTOPPACKAGES[@]} $1)
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"

# Detect distro
grep -q -s "^Amazon Linux AMI" /etc/system-release && DISTRO=ala
test -f /etc/arch-release && DISTRO=arch
test -f /etc/fedora-release && DISTRO=fedora
test -f /etc/pld-release && DISTRO=pld
grep -q -s "Ubuntu" /etc/lsb-release && DISTRO=ubuntu

test -n "$DISTRO" || flunk "unrecognized distro"

WHEEL=wheel

case $DISTRO in
	ala)
		:
		;;
	arch)
		distro_pkg pcre-tools pcre
		compile_pkg etckeeper
		compile_pkg vcsh
		compile_pkg mr
		:
		;;
	fedora)
		:
	;;
	pld)
		distro_pkg zsh zsh-completions
		distro_pkg git git-core
		distro_pkg pcre-tools pcregrep
		distro_pkg ruby ruby-modules
		distro_pkg gnome metapackages-gnome
		;;
	ubuntu)
		WHEEL=adm
		distro_pkg pcre-tools pcregrep
		;;
	*)
		flunk "Unknown Linux distribution"
		;;
esac

# Make sure we are root
test $UID -eq 0 || flunk "Must be root for system bootstrap"

# Import and run init script for this OS
INITSCRIPT="que-sys-init-${DISTRO}.bash"
if [ -f "$DIR/$INITSCRIPT" ]; then
	source "$DIR/$INITSCRIPT"
else
	source <(curl -s -L https://raw.github.com/alerque/que/master/bin/$INITSCRIPT)
fi

# Setup my user
useradd -s $(which zsh) -m -k /dev/null -G $WHEEL caleb

# TODO make sure wheel has sudo permissions

# If we're on a system with etckeeper, make sure it's setup
if which etckeeper; then
	(
	cd /etc 
	etckeeper vcs status || etckeeper init
	etckeeper commit "End of que-sys-bootstrap.bash run"
	)
fi

# For convenience show how to setup my home directory
echo -e "Perhaps you want home stuff too?\n    su - caleb\n    bash <(curl -s -L https://raw.github.com/alerque/que/master/bin/que-home-bootstrap.bash)"

# Setup EC2 tools
#openssl-tools xfsprogs ca-certificates-update
#curl http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
