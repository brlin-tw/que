#!/bin/bash

ISDESKTOP=0
case $1 in
	desktop)
		ISDESKTOP=1
		shift
		;;
esac

# Setup stuff
BASEPACKAGES=(zsh subversion git ctags pcre-tools vim tmux sudo mosh etckeeper ruby zip unzip mr vcsh wget unrar syslog-ng lsof htop gdisk strace ntp)
DESKTOPPACKAGES=(awesome dropbox parcellite chromium flashplugin google-talkplugin owncloud-client gnome rdesktop libreoffice smplayer gimp xiphos transmission-gtk rhythmbox cups gnome-packagekit networkmanager gvfs keepassx ttf-fonts)
COMPILEBASEPACKAGES=()
COMPILEDESKTOPPACKAGES=()

function flunk() {
	echo "Fatal Error: $*"
	exit 0
}

function distro_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/${*:2}})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/${*:2}})
}

function compile_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
	COMPILEBASEPACKAGES=(${COMPILEBASEPACKAGES[@]} $1)
}

function compile_desktop_pkg () {
	BASEPACKAGES=(${BASEPACKAGES[@]/%$1/})
	DESKTOPPACKAGES=(${DESKTOPPACKAGES[@]/%$1/})
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
		distro_pkg flashplugin chromium-pepper-flash-stable
		distro_pkg gnome gnome gnome-{extra,tweaktool,shell-extension-maximus,defaults-list
		distro_pkg libreoffice libreoffice-{gnome,en-US,writer,calc,impress,math,draw} unoconv
		distro_pkg cups cups cups-filters system-config-printer cups-pk-helper gsfonts gutenprint foomatic-{filters,db{,-engine,-nonfree}} hplip splix cups-pdf
		distro_pkg networkmanager networkmanager network-manager-applet
		distro_pkg gvfs gvfs-{mtp,smb,goa,afp}
		distro_pkg xiphos ""
		distro_pkg ttf-fonts ttf-{cheapskate,droid,freefont,gentium,libration,linux-libertine}

		compile_pkg etckeeper
		compile_pkg vcsh
		compile_pkg mr
		compile_desktop_pkg chromium-pepper-flash-stable
		compile_desktop_pkg owncloud-client
		#compile_desktop_pkg xiphos
		compile_desktop_pkg google-talkplugin
		compile_desktop_pkg dropbox
		#compile_desktop_pkg google-chrome
		compile_desktop_pkg gnome-shell-extension-maximus
		compile_desktop_pkg gnome-defaults-list
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

if [ "$ISDESKTOP" == '1' ]; then
	echo "Need to manually install appropriate video driver"
fi
