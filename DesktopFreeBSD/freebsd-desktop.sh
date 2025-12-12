#!/bin/sh

##############################################
# VERSION No. 8
# UPDATED on 2025-04-26
# Autor original: majekla (usuario "tennea9" en The FreeBSD Forums)
# Hilo: "Desktop environments installation script"
# URL hilo: https://forums.freebsd.org/threads/desktop-environments-installation-script.93020/
# Nota: El repositorio original (git.asdf.cafe) ya no está accesible (502 Bad Gateway).

# added a new function : "detect_and_clean_or_keep_existing_de" detecting a previous DE installation and offering you the choice to completely clean it before installing a new one.
# added files to remove for complete deskop environnement removal.
# added checking for kde parameters before setting (net.local.stream.recvspace=65536 and net.local.stream.sendspace=65536)
# added detection of the current repository for "change_repo"

##############################################
# Welcome to this script.
# All functions are described here.
# To see the final execution flow, go directly to the end.
# You can comment out functions if you don't wish them to execute.

##############################################
# DE packages that are used in this script :

export pkg_list_kdemin="xorg sudo sddm kde"

export pkg_list_kdefull="xorg sudo sddm kde freebsd-8k-wallpapers-kde kde-dev-scripts \
kde-dev-utils kde-thumbnailer-chm kde-thumbnailer-epub kde-thumbnailer-fb2 \
kde_poster kdeaccessibility kdeadmin kdeconnect-kde kdegraphics kdemultimedia \
kdevelop calligra kmymoney kdenetwork kdeutils libkdepim wallpapers-freebsd-kde"

export pkg_list_xfcemin="xorg sudo lightdm lightdm-gtk-greeter xfce xdg-user-dirs gvfs"

export pkg_list_xfcefull="xorg sudo lightdm lightdm-gtk-greeter xfce gtk-xfce-engine \
workrave-xfce xfce4-appmenu-plugin xfce4-battery-plugin xfce4-bsdcpufreq-plugin \
xfce4-calculator-plugin xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-dashboard \
xfce4-datetime-plugin xfce4-dev-tools xfce4-dict-plugin xfce4-diskperf-plugin \
xfce4-docklike-plugin xfce4-fsguard-plugin xfce4-generic-slider xfce4-genmon-plugin \
xfce4-goodies xfce4-mixer xfce4-mpc-plugin xfce4-panel-profiles xfce4-places-plugin \
xfce4-pulseaudio-plugin xfce4-volumed-pulse xfce4-whiskermenu-plugin xfce4-windowck-plugin \
xarchiver xdg-user-dirs xfce4-screensaver xfce-icons-elementary \
xfce4-weather-plugin xfce4-netload-plugin xfce4-systemload-plugin \
xfce4-mount-plugin xfce4-notes-plugin xfce4-xkb-plugin gvfs"

export pkg_list_mate="xorg sudo lightdm lightdm-gtk-greeter libmatekbd libmatemixer libmateweather \
libshumate mate mate-applet-appmenu mate-applets mate-backgrounds mate-base mate-calc \
mate-common mate-control-center mate-desktop mate-dock-applet mate-icon-theme \
mate-icon-theme-faenza mate-indicator-applet mate-media mate-menus mate-notification-daemon \
mate-pam-helper mate-panel mate-polkit mate-power-manager mate-screensaver \
mate-session-manager mate-settings-daemon mate-system-monitor mate-terminal \
mate-themes mate-user-guide mate-utils materia-gtk-theme"

export pkg_list_cinnamon="xorg sudo lightdm lightdm-gtk-greeter cinnamon cinnamon-translations"

export pkg_list_gnomemin="xorg sudo gdm gnome-shell gnome-terminal nautilus gnome-tweaks \
gnome-keyring gnome-backgrounds gnome-system-monitor gnome-screenshot \
gnome-power-manager xdg-user-dirs xdg-desktop-portal-gnome"

export pkg_list_lxqt="xorg sudo sddm lxqt lxqt-about lxqt-admin lxqt-archiver \
lxqt-build-tools lxqt-config lxqt-notificationd lxqt-openssh-askpass lxqt-policykit \
lxqt-powermanagement lxqt-runner lxqt-sudo lxqt-themes xdg-desktop-portal-lxqt"

export pkg_list_fvwm="xorg sudo fvwm fvwm-themes"
export pkg_list_wmaker="xorg sudo windowmaker"
export pkg_list_twm="xorg sudo"

export pkg_list_vbox="virtualbox-ose virtualbox-ose-additions"

export gpu_configured=0


################################################################################################################
# FUNCTIONS

# If you can not connect to internet.. then I can do nothing !
checkinternet() {
	clear

    local url="https://www.freebsd.org/"
    echo "- Looking for internet connection, please wait ..." ; sleep 1

    if fetch -q -o /dev/null "$url"; then
        echo "--- OK, let's go on !" ; sleep 1
    else
        echo "Your computer is not connected to the internet, I can't go on."
        exit 0
    fi
}

# Install pkg manager if not already done.
installpkg() {
    printf "\n"
    echo "- Looking for 'pkg', please wait..." ; sleep 1

    if [ ! -x /usr/local/sbin/pkg ]; then
        # Check if pkg can be installed
        if pkg ins -y 2>&1 | grep -q "error"; then
            echo "I can't install pkg, please check your internet connection"
            printf "\n"
            exit 0
        fi
    fi
    echo "--- OK, let's go on !" ; sleep 1
}

# Welcome !
welcome() {
    if ! bsddialog --yesno "        Welcome to this installation script for setting up\n                a Desktop Environment on FreeBSD.\n\nCurrently, it allows you to install KDE, XFCE, GNOME, Mate, Cinnamon, LXQT, FVWM, WindowMaker or Twm.\nSince some desktop environments are feature-rich (such as KDE, XFCE, GNOME), you have the option to choose between a minimal and a more complete version.\n\nSeveral options will be offered to you (autologin, selection of standard applications for your desktop environment, hypervisor installation, etc.).\n\nA basic graphics card detection feature is included. It relies on detection using "pciconf" and is therefore not exhaustive.\nHowever, if you use an NVIDIA GPU, you need to know which driver version is required for your graphics card. You will be asked to choose between versions 304, 340, 390, 470 and 570\n\nTo enable the installation of a desktop environment, a user (other than root) must be created. If you haven't created one during the FreeBSD installation process, you'll be able to do so here.\n\nFurthermore, correct UEFI configuration is obviously not supported by this script. Generally, a few things must be done before (disable GPU switchable graphics etc.)\n\n                             Good luck!"  26 70; then
        echo 'I quit, bye !'
        exit 0
    fi
}

# Check for Desktop Environnement packages availability before going on
check_packages_availability() {

	if ! bsddialog --yesno "I can check the availability of the desktop environment packages\n  in the repository and inform you if there was a build issue.\n\n  It takes about 5 minutes, but you really should check before\n                             going on." 9 70; then
        return
    fi

	pkg_vars="pkg_list_kdemin pkg_list_kdefull pkg_list_xfcemin pkg_list_xfcefull pkg_list_mate pkg_list_cinnamon pkg_list_gnomemin pkg_list_lxqt pkg_list_fvwm pkg_list_wmaker pkg_list_twm pkg_list_vbox"

	TEMP=$(mktemp)
	: > "$TEMP"
	TEMP2=$(mktemp)
	: > "$TEMP2"

	for pkg_var in $pkg_vars; do
		eval pkg_list="\${$pkg_var}"
		pkg_missing="no"
		missing_pkgs=""

		for pkgname in $pkg_list; do
			latest_version=$(pkg rquery '%v' "$pkgname" 2>/dev/null)

			if [ -z "$latest_version" ]; then
				pkg_missing="yes"
				missing_pkgs="$missing_pkgs $pkgname"
			fi
		done

		if [ "$pkg_missing" = "yes" ]; then
			case "$pkg_var" in
				pkg_list_kdemin) env_name="|--KDE-(min)";;
				pkg_list_kdefull) env_name="|--KDE-(full)";;
				pkg_list_xfcemin) env_name="|--XFCE-(min)";;
				pkg_list_xfcefull) env_name="|--XFCE-(full)";;
				pkg_list_mate) env_name="|--MATE";;
				pkg_list_cinnamon) env_name="|--CINNAMON-(full)";;
				pkg_list_gnomemin) env_name="|--GNOME-(min)";;
				pkg_list_lxqt) env_name="|--LXQt";;
				pkg_list_fvwm) env_name="|--FVWM";;
				pkg_list_vbox) env_name="|--VirtualBox";;
				pkg_list_wmaker) env_name="|--WindowMaker";;
				pkg_list_twm) env_name="|--TWM (Xorg)";;
			esac
			echo "$env_name:$missing_pkgs" >> "$TEMP"
			echo "" >> "$TEMP"

			tr ' ' '\n' < $TEMP > $TEMP2
		fi
	done

	dialog --backtitle "Results" --title "Missing Packages in the repo" --textbox "$TEMP2" 25 50
    if ! bsddialog --yesno "Now that you know, do you still want to continue?" 5 54; then
		echo "Good Bye"
		echo "You should wait a few days and check on https://pkg-status.freebsd.org"
		exit 0
    fi

	rm "$TEMP" "$TEMP2"
}

# System Update
update() {
    if bsddialog --yesno "Do you want to update your system before starting?\n          (freebsd-update fetch/install)" 6 54; then
        bsddialog --msgbox "Please review the available changes, then press 'q' to continue" 5 67
        freebsd-update fetch
        freebsd-update install
    fi
}

# Create a BE before going on ?
create_boot_environment() {

	# Check if filesystem is ZFS or not
	fstype=$(df -T / | awk 'NR==2 {print $2}')
	if [ ! "$fstype" = "zfs" ]; then
		bsddialog --msgbox "This function is reserved for the ZFS filesystem." 5 53
		return
	fi

	date=$(date +"%Y%m%d-%H%M%S")

	if bsddialog --yesno "Do you want to create a boot environment before installation?" 5 65; then

		pkg info -e beadm || pkg install -y beadm

	    if ! beadm create DE-install_$date; then
	        bsddialog --msgbox "Error creating the boot environment." 5 40
	    else
			bsddialog --msgbox "I created a new boot environment named 'DE-install_$date'" 5 71
		fi
	fi

}

# Change repository
change_repo() {
    REPO=$(pkg -vv | awk '/Repositories:/ {flag=1} flag && /url/ {split($3,a,"/"); gsub(/"|,/,"",a[length(a)]); print a[length(a)]; exit}')
	CHOICE=$(bsddialog --title "Change your Repository? (current : $REPO)" \
		--radiolist "Please select an option:" 10 65 3 \
		1 "Quarterly  (rebuilt every quarter)" off \
		2 "Latest     (continuously updated)" off \
		3 "Do not change the actual configuration" on \
		3>&1 1>&2 2>&3)

	if [ $? -eq 0 ]; then
		case $CHOICE in
		    1)
		        sed -i "" "s/latest/quarterly/" /etc/pkg/FreeBSD.conf
				pkg remove -yf pkg ; sleep 2 ; pkg ins -y pkg
				pkg update -f ; sleep 2 ; pkg update -f
		        ;;
		    2)
		        sed -i "" "s/quarterly/latest/" /etc/pkg/FreeBSD.conf
				pkg remove -yf pkg ; sleep 2 ; pkg ins -y pkg
				pkg update -f ; sleep 2 ; pkg update -f
		        ;;
		esac
	fi
}

# User
user_for_desktop() {
    if bsddialog --yesno "Have you already created the user who will use the desktop?" 5 63; then
        for j in $(seq 4); do
            # Username of the desktop environment user
            user=$(bsddialog --inputbox "Please enter his username" 8 29 2>&1 1>/dev/tty)

            #check if the user already exists or not
            if ! getent passwd "$user" >/dev/null; then
                bsddialog --msg "                      !WARNING!\n               This user does not exist\n                   Please try again" 7 58
            else
                break
            fi
        done

        # Exit script if not able to choose a user
        if [ $j -eq 4 ]; then
            exit 0
        fi
    else
        for i in $(seq 4); do

            user=$(bsddialog --inputbox "What username would you like to give to your user?\n        (No spaces or special characters)" 9 54 2>&1 1>/dev/tty)
            fullname=$(bsddialog --inputbox "Please enter his full name (don't leave empty)" 8 50 2>&1 1>/dev/tty)

            #check if the user already exists or not
            if getent passwd "$user" >/dev/null; then
                if bsddialog --yesno "                      !WARNING!\n               This user already exists\nDo you want to use it [Yes] or create another one [No]" 7 58; then
                    break
                fi
            else
                pw useradd "$user" -d "/home/$user" -m -c "$fullname"
                clear
                echo "--------------------------------------"
                echo "Please assign a password to $user"
                printf "\n"
                passwd $user
                break
            fi
        done

        # Exit script if not able to create a user
        if [ $i -eq 4 ]; then
            exit 0
        fi
    fi
}


##############
# Detect a previous DE installation

detect_and_clean_or_keep_existing_de() {

    # --------------------
    # Check for KDE :
    check_previous_kde_install() {
        grep -q '^\s*sddm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf && \
        [ "$(sysctl -n net.local.stream.recvspace)" -eq 65536 ] && \
        [ "$(sysctl -n net.local.stream.sendspace)" -eq 65536 ] && \
        grep -q '^proc /proc procfs rw 0 0' /etc/fstab || return 1

        pkg info -q kde || return 1

        return 0
    }

    if check_previous_kde_install; then
        # Decide to clear KDE installation or not.
        if bsddialog --default-no --yesno "A previous KDE installation has been detected.\n          Do you want to clear it ?" 6 50; then
            echo 'I clean KDE installation now'

        sysrc -x sddm_enable dbus_enable
            sed -i '' 's/net\.local\.stream\.recvspace=65536//' /etc/sysctl.conf
            sed -i '' 's/net\.local\.stream\.sendspace=65536//' /etc/sysctl.conf
        sed -i '' 's/proc \/proc procfs rw 0 0//' /etc/fstab
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_kdefull; do
            pkg remove -yf $pkg*
        done

        cd /home/"$user"
        rm .Xauthority
        rm -rf .dbus
        rm -rf .config
        rm -rf .local
        rm .xsession*
        rm -f drkonqi.core
        rm -f kcminit.core
        rm -f ksplashqml.core
        rm -f plasmashell.core
        rm -f .dmrc
        rm -f .gtkrc-2.0

        pkg delete -y $(pkg info | grep -i kde | awk '{print $1}')
        pkg delete -y $(pkg info | grep -i plasma | awk '{print $1}')

        if bsddialog --yesno "           KDE has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi


    # --------------------
    # Check for XFCE :

    check_previous_xfce_install() {
        grep -q '^\s*lightdm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf && \
        grep -q '^proc /proc procfs rw 0 0' /etc/fstab || return 1

        pkg info -q xfce || return 1

        return 0
    }

    if check_previous_xfce_install; then
        # Decide to clear Xfce installation or not.
        if bsddialog --default-no --yesno "A previous Xfce installation has been detected.\n          Do you want to clear it ?" 6 51; then
            echo 'I clean Xfce installation now'

        sysrc -x lightdm_enable dbus_enable
        sed -i '' 's/proc \/proc procfs rw 0 0//' /etc/fstab
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_xfcefull; do
            pkg remove -yf $pkg*
        done

        cd /home/"$user"
        rm -rf .dbus
        rm -rf .config
        rm -f .dmrc
        rm -rf .gnupg
        rm -rf .local
        rm -rf .cache
        rm .xsession*
        rm .ICEauthority
        rm .Xauthority
        rm -f .dmrc
        rm -f .gtkrc-2.0

        pkg delete -y $(pkg info | grep -i xfce | awk '{print $1}')

        if bsddialog --yesno "           Xfce has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi


    # --------------------
    # Check for MATE :

    check_previous_mate_install() {
        grep -q '^\s*lightdm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf && \
        grep -q '^proc /proc procfs rw 0 0' /etc/fstab || return 1

        pkg info -q mate || return 1

        return 0
    }

    if check_previous_mate_install; then
        # Decide to clear Mate installation or not.
        if bsddialog --default-no --yesno "A previous Mate installation has been detected.\n          Do you want to clear it ?" 6 51; then
            echo 'I clean Mate installation now'

        sysrc -x lightdm_enable dbus_enable
        sed -i '' 's/proc \/proc procfs rw 0 0//' /etc/fstab
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_mate; do
            pkg remove -yf $pkg*
        done

        cd /home/"$user"
        rm -rf .dbus
        rm -rf .config
        rm -f .dmrc
        rm -rf .gnupg
        rm -rf .local
        rm -rf .cache
        rm .xsession*
        rm .ICEauthority
        rm .Xauthority
        rm -f .dmrc
        rm -f .gtkrc-2.0

        pkg delete -y $(pkg info | grep -i mate | awk '{print $1}')

        if bsddialog --yesno "           Mate has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi


    # --------------------
    # Check for CINNAMON :

    check_previous_cinnamon_install() {
        grep -q '^\s*lightdm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf && \
        grep -q '^proc /proc procfs rw 0 0' /etc/fstab || return 1

        pkg info -q cinnamon || return 1

        return 0
    }

    if check_previous_cinnamon_install; then
        # Decide to clear Mate installation or not.
        if bsddialog --default-no --yesno "A previous Cinnamon installation has been detected.\n              Do you want to clear it ?" 6 55; then
            echo 'I clean Cinnamon installation now'

        sysrc -x lightdm_enable dbus_enable
        sed -i '' 's/proc \/proc procfs rw 0 0//' /etc/fstab
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_cinnamon; do
            pkg remove -yf $pkg*
        done

        cd /home/"$user"
        rm -rf .dbus
        rm -rf .config
        rm -f mate-panel.core
        rm -rf .cinnamon
        rm -f .dmrc
        rm -rf .local
        rm -rf .cache
        rm .xsession*
        rm .Xauthority
        rm -f .dmrc

        pkg delete -y $(pkg info | grep -i cinnamon | awk '{print $1}')

        if bsddialog --yesno "         Cinnamon has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi

    # --------------------
    # Check for GNOME:

    check_previous_gnome_install() {
        grep -q '^\s*gdm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf && \
        grep -q '^proc /proc procfs rw 0 0' /etc/fstab || return 1

        pkg info -q gnome-shell || return 1
        pkg info -q gnome-terminal || return 1
        pkg info -q nautilus || return 1

        return 0
    }

    if check_previous_gnome_install; then
        # Decide to clear Gnome installation or not.
        if bsddialog --default-no --yesno "A previous Gnome installation has been detected.\n           Do you want to clear it ?" 6 52; then
            echo 'I clean Gnome installation now'

        sysrc -x gdm_enable dbus_enable
        sed -i '' 's/proc \/proc procfs rw 0 0//' /etc/fstab
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        cd /home/"$user"
        rm -rf .dbus
        rm -rf .config
        rm -rf .local
        rm -rf .cache
        rm .xsession*
        rm .Xauthority
        rm -f .dmrc

        pkg delete -y $(pkg info | grep -i gnome | awk '{print $1}')

        if bsddialog --yesno "           Gnome has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi

    # --------------------
    # Check for LXQT:

    check_previous_lxqt_install() {
        grep -q '^\s*sddm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf && \
        grep -q '^proc /proc procfs rw 0 0' /etc/fstab || return 1

        pkg info -q lxqt || return 1

        return 0
    }

    if check_previous_lxqt_install; then
        # Decide to clear Lxqt installation or not.
        if bsddialog --default-no --yesno "A previous lxqt installation has been detected.\n           Do you want to clear it ?" 6 51; then
            echo 'I clean lxqt installation now'

        sysrc -x sddm_enable dbus_enable
        sed -i '' 's/proc \/proc procfs rw 0 0//' /etc/fstab
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_lxqt; do
            pkg remove -yf $pkg*
        done

        cd /home/"$user"
        rm -rf .dbus
        rm -rf .config
        rm -rf .local
        rm -rf .cache

        pkg delete -y $(pkg info | grep -i lxqt | awk '{print $1}')

        if bsddialog --yesno "            Lxqt has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi


    # --------------------
    # Check for FVWM:

    check_previous_fvwm_install() {
        grep -q '^\s*sddm_enable="YES"' /etc/rc.conf && \
        grep -q '^\s*dbus_enable="YES"' /etc/rc.conf

        pkg info -q fvwm || return 1

        return 0
    }

    if check_previous_fvwm_install; then
        # Decide to clear fvwm installation or not.
        if bsddialog --default-no --yesno "A previous fvwm installation has been detected.\n           Do you want to clear it ?" 6 51; then
            echo 'I clean fvwm installation now'

        sysrc -x sddm_enable dbus_enable
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_fvwm; do
            pkg remove -yf $pkg
        done

        if bsddialog --yesno "            fvwm has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi


    # --------------------
    # Check for WINDOWMAKER:

    check_previous_wmaker_install() {

        pkg info -q windowmaker || return 1

        return 0
    }

    if check_previous_wmaker_install; then
        # Decide to clear windowmaker installation or not.
        if bsddialog --default-no --yesno "A previous windowmaker installation has been detected.\n               Do you want to clear it ?" 6 58; then
            echo 'I clean windowmaker installation now'

        sysrc -x sddm_enable dbus_enable
        pw groupmod video -d "$user"
        rm -f /home/"$user"/.xinitrc

        for pkg in $pkg_list_wmaker; do
            pkg remove -yf $pkg
        done

        if bsddialog --yesno "         windowmaker has been entirely removed.\nYou should restart before installing another desktop.\n             Do you want to restart now ?" 7 57; then
            reboot
        fi

        fi
    fi
}

##############
# DE choices:

kde-sddm_min() {

    for pkg in $pkg_list_kdemin; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc sddm_enable=YES dbus_enable=YES

    if ! grep -q "net.local.stream.recvspace=65536" /etc/sysctl.conf; then
        echo "net.local.stream.recvspace=65536" >> /etc/sysctl.conf
    fi

    if ! grep -q "net.local.stream.sendspace=65536" /etc/sysctl.conf; then
        echo "net.local.stream.sendspace=65536" >> /etc/sysctl.conf
    fi

    pw groupmod video -m "$user"

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    echo "exec ck-launch-session startplasma-x11" > /home/"$user"/.xinitrc

	session_autologin="plasma"
}

kde-sddm_full() {

    for pkg in $pkg_list_kdefull; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc sddm_enable=YES dbus_enable=YES

    if ! grep -q "net.local.stream.recvspace=65536" /etc/sysctl.conf; then
        echo "net.local.stream.recvspace=65536" >> /etc/sysctl.conf
    fi

    if ! grep -q "net.local.stream.sendspace=65536" /etc/sysctl.conf; then
        echo "net.local.stream.sendspace=65536" >> /etc/sysctl.conf
    fi

    pw groupmod video -m "$user"

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    echo "exec ck-launch-session startplasma-x11" > /home/"$user"/.xinitrc

	session_autologin="plasma"

}

xfce-lightdm_min() {

    for pkg in $pkg_list_xfcemin; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc lightdm_enable=YES dbus_enable=YES

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    cp /usr/local/etc/xdg/xfce4/xinitrc /home/"$user"/.xinitrc

}

xfce-lightdm_full() {

    for pkg in $pkg_list_xfcefull; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc lightdm_enable=YES dbus_enable=YES

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    cp /usr/local/etc/xdg/xfce4/xinitrc /home/"$user"/.xinitrc

}

mate-lightdm() {

    for pkg in $pkg_list_mate; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc lightdm_enable=YES dbus_enable=YES

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    echo "exec ck-launch-session mate-session" > /home/"$user"/.xinitrc

}

cinnamon-lightdm() {

    for pkg in $pkg_list_cinnamon; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc lightdm_enable=YES dbus_enable=YES

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    echo "exec ck-launch-session cinnamon-session" > /home/"$user"/.xinitrc

}

gnome-gdm_min() {

    for pkg in $pkg_list_gnomemin; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc gdm_enable=YES dbus_enable=YES

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    echo "exec gnome-session" > /home/"$user"/.xinitrc

}

lxqt-sddm() {

    for pkg in $pkg_list_lxqt; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

    sysrc sddm_enable=YES dbus_enable=YES

    if ! grep -q "proc /proc procfs rw 0 0" /etc/fstab; then
        echo "proc /proc procfs rw 0 0" >> /etc/fstab
    fi

    echo "exec ck-launch-session startlxqt" > /home/"$user"/.xinitrc

	session_autologin="lxqt"

}

fvwm() {

    for pkg in $pkg_list_fvwm; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

	pw groupmod video -m "$user"

	sysrc sddm_enable=YES dbus_enable=YES

	echo "exec fvwm" > /home/"$user"/.xinitrc

	session_autologin="fvwm"

}

wmaker() {

    for pkg in $pkg_list_wmaker; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

	pw groupmod video -m "$user"

	echo "exec wmaker" > /home/"$user"/.xinitrc

}

twm() {

    for pkg in $pkg_list_twm; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
		echo "| - \"$pkg\" installed"
    done

}


####################
# Autologin options

autologin() {
    if bsddialog --yesno "Do you want to enable automatic login at desktop startup?" 5 61; then
        if [ -f /usr/local/bin/sddm ]; then
            # SDDM detected
            cat <<EOF >> /usr/local/etc/sddm.conf
[Autologin]
User=$user
Session=$session_autologin
EOF
            bsddialog --msgbox "Autologin configured for SDDM." 5 34

        elif [ -f /usr/local/sbin/lightdm ]; then
            # LightDM detected
            sed -i "" "s/#autologin-user=/autologin-user=$user/" /usr/local/etc/lightdm/lightdm.conf
            sed -i "" "s/#autologin-user-timeout=0/autologin-user-timeout=0/" /usr/local/etc/lightdm/lightdm.conf
            bsddialog --msgbox "Autologin configured for LightDM." 5 37

        else
            bsddialog --msgbox "Neither SDDM nor LightDM detected. No changes made." 5 55
        fi
    fi
}


###########
# DE menus

kde-sddm_choice() {
    DE=$(bsddialog --clear \
                    --backtitle "KDE-SDDM" \
                    --title "Desktop Environment" \
                    --menu "Select your Desktop Environment:" \
                    9 40 10 \
                    1 "Minimal KDE environment" \
                    2 "Full    KDE environment" \
                    3>&1 1>&2 2>&3)

    case $? in
        0)
            case $DE in
                1) kde-sddm_min ;;
                2) kde-sddm_full ;;
            esac
            ;;
        1|255) desktop_selection_menu ;;
    esac
}

xfce-lightdm_choice() {
    DE=$(bsddialog --clear \
                    --backtitle "XFCE-LIGHTDM" \
                    --title "Desktop Environment" \
                    --menu "Select your Desktop Environnment:" \
                    9 40 10 \
                    1 "Minimal Xfce environment" \
                    2 "Full    Xfce environment" \
                    3>&1 1>&2 2>&3)

    case $? in
        0)
            case $DE in
                1) xfce-lightdm_min ;;
                2) xfce-lightdm_full ;;
            esac
            ;;
        1|255) desktop_selection_menu ;;
    esac
}

gnome-gdm_choice() {
    DE=$(bsddialog --clear \
                    --backtitle "GNOME-GDM" \
                    --title "Desktop Environment" \
                    --menu "Select your Desktop Environnment:" \
                    9 40 10 \
                    1 "Minimal GNOME environment" \
                    
                    3>&1 1>&2 2>&3)

    case $? in
        0)
            case $DE in
                1) gnome-gdm_min ;;
            esac
            ;;
        1|255) desktop_selection_menu ;;
    esac
}

# DE selection
desktop_selection_menu() {
    DE=$(bsddialog --clear \
                    --backtitle "Desktop Environnments" \
                    --title "Desktop Environnment" \
                    --menu "Select your Desktop Environnment:" \
                    17 70 10 \
                    1 "KDE           (with sddm)" \
                    2 "XFCE4         (with lightdm)" \
                    3 "MATE          (with lightdm)" \
                    4 "CINNAMON      (with lightdm)" \
                    5 "GNOME         (with gdm)" \
                    6 "LXQT          (with sddm)" \
					7 "FVWM" \
					8 "WINDOWMAKER" \
					9 "TWM" \
                    10 "(none)" \
                    3>&1 1>&2 2>&3)

    case $DE in
        1) kde-sddm_choice ;;
        2) xfce-lightdm_choice ;;
        3) mate-lightdm ;;
        4) cinnamon-lightdm ;;
        5) gnome-gdm_choice ;;
        6) lxqt-sddm ;;
		7) fvwm ;;
		8) wmaker ;;
		9) twm ;;
        10) automatic_graphics_detection ;;
    esac
}


############################################################################################
# Which GPU ?

intel-irisxe() {
cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-scfb.conf
Section "Device"
    Identifier "Card0"
    Driver "scfb"
    BusID "$intelirisxe_pci_location"
EndSection
EOF

gpu_configured=1
}

vbox() {
cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-vbox.conf
# This configuration file is useless.
# It only permits autodetection.
EOF

gpu_configured=1
}

intel-older() {
    clear

    pkg_list_intelgpu="xf86-video-intel drm-kmod"

    for pkg in $pkg_list_intelgpu; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
    done

    sysrc kld_list+=" i915kms" > /dev/null 2>&1

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-intel.conf
Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
   #Option      "AccelMethod" "sna"
   #Option      "TearFree"    "true"
   #Option      "DRI"         "3"
   #Option      "Backlight"   "intel_backlight"
   BusID       "$intel_pci_location"
EndSection
EOF

gpu_configured=1
}

nvidia-gpu() {
    TMPFILE=$(mktemp)

    bsddialog --backtitle "Select your GPU driver" \
        --title "Installing graphics" \
        --radiolist "Select driver:" 12 60 9 \
        "nvidia-driver-304" "Legacy NVIDIA driver 304" off \
        "nvidia-driver-340" "Legacy NVIDIA driver 340" off \
        "nvidia-driver-390" "Legacy NVIDIA driver 390" off \
        "nvidia-driver-470" "Legacy NVIDIA driver 470" off \
        "nvidia-driver-570" "Latest NVIDIA driver 570" off 2> "$TMPFILE"

    choice=$(< "$TMPFILE" sed 's/"//g')
    rm -f "$TMPFILE"

    case "$choice" in

        "nvidia-driver-304")

            pkg_list_nvidia304="nvidia-driver-304"

            for pkg in $pkg_list_nvidia304; do
                pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
            done

            sysrc kld_list+=" nvidia" > /dev/null 2>&1

            # BusID detection
            pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'NVIDIA')
            nvidia_pci_location=$(echo "$pciconf_output" | \
                sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | \
                sed 's/0://')

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf
Section "Device"
Identifier  "Device0"
Driver      "nvidia"
VendorName  "NVIDIA Corporation"
BusID       "$nvidia_pci_location"
EndSection

Section "ServerFlags"
Option      "IgnoreABI" "1"
EndSection
EOF
        gpu_configured=1

        ;;
        "nvidia-driver-340")

            pkg_list_nvidia340="nvidia-driver-340"

            for pkg in $pkg_list_nvidia340; do
                pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
            done

            sysrc kld_list+=" nvidia" > /dev/null 2>&1

            # BusID detection
            pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'NVIDIA')
            nvidia_pci_location=$(echo "$pciconf_output" | \
                sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | \
                sed 's/0://')

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf
Section "Device"
Identifier  "Device0"
Driver      "nvidia"
VendorName  "NVIDIA Corporation"
BusID       "$nvidia_pci_location"
EndSection
EOF
        gpu_configured=1

        ;;
        "nvidia-driver-390")

            pkg_list_nvidia390="nvidia-driver-390"

            for pkg in $pkg_list_nvidia390; do
                pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
            done

            sysrc kld_list+=" nvidia-modeset" > /dev/null 2>&1

            # BusID detection
            pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'NVIDIA')
            nvidia_pci_location=$(echo "$pciconf_output" | \
                sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | \
                sed 's/0://')

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf
Section "Device"
Identifier  "Device0"
Driver      "nvidia"
VendorName  "NVIDIA Corporation"
BusID       "$nvidia_pci_location"
EndSection
EOF
        gpu_configured=1

        ;;
        "nvidia-driver-470")

            pkg_list_nvidia470="nvidia-driver-470"

            for pkg in $pkg_list_nvidia470; do
                pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
            done

            sysrc kld_list+=" nvidia-modeset" > /dev/null 2>&1
            # BusID detection
            pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'NVIDIA')
            nvidia_pci_location=$(echo "$pciconf_output" | \
                sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | \
                sed 's/0://')

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf
Section "Device"
Identifier  "Device0"
Driver      "nvidia"
VendorName  "NVIDIA Corporation"
BusID       "$nvidia_pci_location"
EndSection
EOF
        gpu_configured=1

        ;;
        "nvidia-driver-570")

            pkg_list_nvidia570="nvidia-driver"

            for pkg in $pkg_list_nvidia570; do
                pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
            done

            sysrc kld_list+=" nvidia-modeset" > /dev/null 2>&1

            # BusID detection
            pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'NVIDIA')
            nvidia_pci_location=$(echo "$pciconf_output" | \
                sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | \
                sed 's/0://')

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf
Section "Device"
Identifier  "Device0"
Driver      "nvidia"
VendorName  "NVIDIA Corporation"
BusID       "$nvidia_pci_location"
EndSection
EOF
        gpu_configured=1

        ;;
    esac
}

amd-cpu_amd-gpu() {
    clear

    pkg_list_amdgpu="xf86-video-amdgpu drm-kmod gpu-firmware-kmod"

    for pkg in $pkg_list_amdgpu; do
        pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
    done

    sysrc kld_list+=" amdgpu" > /dev/null 2>&1

    gpu_configured=1
}

graphics_selection_menu() {
    GPU=$(bsddialog --clear \
                    --backtitle "GPU" \
                    --title "GPU Menu" \
                    --menu "Select your graphics:" \
                    13 70 10 \
                    1 "Intel Iris Xe" \
                    2 "Intel (before Iris Xe)" \
                    3 "Nvidia" \
                    4 "AMD" \
                    5 "Restart automatic GPU detection" \
                    6 "Virtual Machine" \
                    3>&1 1>&2 2>&3)

    case $GPU in
        1) intel-irisxe ;;
        2) intel-older ;;
        3) nvidia-gpu ;;
        4) amd-gpu ;;
        5) automatic_graphics_detection ;;
        6) programs_selection_menu ;;
    esac

}

automatic_graphics_detection() {
    # Check if there is an already existing configuration file :
    if [ -e /usr/local/etc/X11/xorg.conf.d/00-scfb.conf ] || \
       [ -e /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf ] || \
       [ -e /usr/local/etc/X11/xorg.conf.d/00-intel.conf ] || \
       [ -e /usr/local/etc/X11/xorg.conf.d/00-vbox.conf ]; then

        bsddialog --yesno "I have detected a previous graphics configuration file\n    Do you want to use it [Yes] or erase it [No]?" 6 58
        existingconf_ornot=$?

        if [ $existingconf_ornot -eq 0 ]; then
            useconf="1"
            return
        else
            rm /usr/local/etc/X11/xorg.conf.d/00-scfb.conf 2>&1
            rm /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf 2>&1
            rm /usr/local/etc/X11/xorg.conf.d/00-intel.conf 2>&1
            rm /usr/local/etc/X11/xorg.conf.d/00-vbox.conf 2>&1

            graphics_selection_menu
			return
        fi
    fi


    if [ "$useconf" != "1" ]; then
        # VIRTUALBOX
        vbox_pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 "'SVGA II Adapter")
        vbox_pci_location=$(echo "$vbox_pciconf_output" | sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | sed 's/0://')

        # INTEL IRIS Xe
        intelirisxe_pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'Iris Xe')
        intelirisxe_pci_location=$(echo "$intelirisxe_pciconf_output" | sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | sed 's/0://')

        # INTEL (before Iris Xe)
        intel_pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 "HD Graphics")
        intel_pci_location=$(echo "$intel_pciconf_output" | sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | sed 's/0://')

        # NVIDIA
        nvidia_pciconf_output=$(pciconf -lv | grep -B3 'display' | grep -B2 'NVIDIA')
        nvidia_pci_location=$(echo "$nvidia_pciconf_output" | sed -nE 's/^vgapci[0-9]+@pci([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/PCI:\1/p' | sed 's/0://')


        # If 2 graphics are detected (Intel Iris Xe and NVIDIA), please choose between
        if [ ! -z "$intelirisxe_pciconf_output" ] && \
           [ ! -z "$nvidia_pciconf_output" ]; then

            bsddialog --yesno "We have detected both Intel Iris Xe and NVIDIA graphics\n        Use Intel Iris Xe [Yes] or NVIDIA [No]?" 6 59
            intel_ornvidia=$?

            if [ $intel_ornvidia -eq 0 ]; then
                intel-irisxe
				return
            else
                nvidia-gpu
				return
            fi
        fi

        # If 2 graphics are detected (Intel and NVIDIA), please choose between
        if [ ! -z "$intel_pciconf_output" ] && \
           [ ! -z "$nvidia_pciconf_output" ]; then

            bsddialog --yesno "We have detected both Intel and NVIDIA graphics\n        Use Intel [Yes] or NVIDIA [No]?" 6 51
            intel_ornvidia=$?

            if [ $intel_ornvidia -eq 0 ]; then
                intel-older
				return
            else
                nvidia-gpu
				return
            fi
        fi

        # If VirtualBox is detected, ask to accept or not :
        if [ ! -z "$vbox_pciconf_output" ]; then
                vbox
				return
        fi

        # If an Intel Iris Xe is detected, ask to accept or not :
        if [ ! -z "$intelirisxe_pciconf_output" ]; then
                intel-irisxe
				return
        fi

        # If an Intel is detected, ask to accept or not :
        if [ ! -z "$intel_pciconf_output" ]; then
                intel-older
				return
        fi

        # If an NVIDIA is detected, ask to accept or not :
        if [ ! -z "$nvidia_pciconf_output" ]; then
                nvidia-gpu
				return
        fi

        # If no choice has been done, go to graphics_selection_menu :
        if [ ! -e /usr/local/etc/X11/xorg.conf.d/00-scfb.conf ] && \
           [ ! -e /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf ] && \
           [ ! -e /usr/local/etc/X11/xorg.conf.d/00-intel.conf ] && \
           [ ! -e /usr/local/etc/X11/xorg.conf.d/00-vbox.conf ]; then

            graphics_selection_menu
			return
        fi
    fi

    # If a GPU has been configured, then leave the function
    if [ "$gpu_configured" -eq 1 ]; then
        return 0
    fi

    # Check if there is an already existing configuration file :
    if [ ! -e /usr/local/etc/X11/xorg.conf.d/00-scfb.conf ] && \
       [ ! -e /usr/local/etc/X11/xorg.conf.d/00-nvidia.conf ] && \
       [ ! -e /usr/local/etc/X11/xorg.conf.d/00-intel.conf ] && \
       [ ! -e /usr/local/etc/X11/xorg.conf.d/00-vbox.conf ]; then

        graphics_selection_menu
		return
    fi
}

# DragonFly Mail Agent
dma() {

	if ! bsddialog --yesno "Do you want to configure Dragonfly Mail Agent?" 5 50; then
		    return
	fi

    HOSTNAME=$(hostname)
    MAILSERVER=$(bsddialog --inputbox " DMA : Address of mailserver" 8 33 2>&1 1>/dev/tty)
    if [ -e /etc/dma/dma.conf ]; then
        mv /etc/dma/dma.conf /etc/dma/dma.conf.original
    fi
    cat <<EOF  >  /etc/dma/dma.conf
SMARTHOST $MAILSERVER
MAILNAME  $HOSTNAME
NULLCLIENT
EOF
        cat <<EOF >> /etc/rc.conf
# Disable sendmail
sendmail_enable="NO"
sendmail_submit_enable="NO"
sendmail_outbound_enable="NO"
sendmail_msp_queue_enable="NO"
EOF
    bsddialog --msgbox "Don't forget to take a look at /etc/dma/dma.conf" 5 52
}

programs_selection_menu() {
    # Install usual programs
    TMPFILE=$(mktemp)

    bsddialog --backtitle "Select usual programs" \
        --title "Installing applications" \
        --checklist "Select usual programs:" 30 70 20 \
        "firefox " "Firefox web browser" off \
        "ungoogled-chromium " "Chromium web browser without Google" off \
        "chrome-linux " "Linux compat chrome for Netflix" off \
        "brave-linux " "Linux compat brave" off \
        "edge-linux " "Linux compat edge" off \
        "opera-linux " "Linux compat opera" off \
        "vivaldi-linux " "Linux compat vivaldi" off \
        "qutebrowser " "Qutebrowser vim-like web browser" off \
        "tor-browser " "Tor Browser for FreeBSD" off \
        "midori " "Midori web browser" off \
        "thunderbird "  "Thunderbird Mail Client" off \
        "claws-mail " "Claws-Mail Client" off \
        "remmina " "Remote Desktop Viewer" off \
        "tigervnc-server " "TigerVNC Server" off \
        "tigervnc-viewer " "TigerVNC Viewer" off \
        "anydesk " "Remote Desktop access" off \
		"rxvt-unicode " "rxvt modified to support Unicode" off \
		"alacritty " "GPU-accelerated terminal emulator" off \
        "neofetch " "highly customizable system info script" off \
        "putty " "Putty term" off \
        "hexchat " "HexChat IRC client" off \
        "pidgin " "Pidgin messaging client" off \
        "psi " "PSI messaging client" off \
        "codeblocks " "Code Editor" off \
        "vscode " "Code Editor" off \
        "vlc " "VLC multimedia player" off \
        "handbrake " "HandBrake video encoder" off \
        "ffmpeg " "Video library" off \
        "audacity " "Audacity audio editor" off \
        "gtk-mixer " "Sound controller" off \
        "gimp " "GIMP image editor" off \
        "nomacs " "easy image viewer/editor" off \
        "ristretto " "Ristretto image viewer" off \
        "libreoffice " "LibreOffice office suite" off \
        "abiword " "Text editor" off \
        "qpdfview " "PDF document viewer" off \
        "evince " "PFD reader" off \
        "okular " "PDF reader" off \
        "filezilla " "FileZilla FTP client" off \
		"rsync " "Network file sync utility" off \
        "restic " "Restic Simplified Backup tool" off \
        "rclone " "Rclone file transfer tool" off \
        "rclone-browser " "GUI rclone" off \
        "7-zip " "7z file archiver" off \
        "keepassxc " "KeePassXC password manager" off \
        "keepass " "KeePass password manager" off \
        "1password-client " "1Password manager" off \
        "1password-client2 " "1Password manager" off \
        "openvpn " "OpenVPN Virtual Private Network setup" off \
        "tor " "Tor decentralized anonymous network" off \
        "wireshark " "Wireshark network protocol analyzer" off \
        "nmap " "Nmap network discovery tool" off \
        "liferea " "RSS agregator" off \
        "musescore " "Sheet music editor" off \
        "httrack " "web-site sucker" off 2>$TMPFILE


    choices=$(sed 's/"//g' < $TMPFILE | tr ' ' '\n')

    # Install the selected programs.
    for choice in $choices; do

        case $choice in
            "firefox")

                pkg_list="firefox"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "firefox-esr"
                done

            ;;
            "chrome-linux")

                pkg_list="wget git"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
                done


                if [ ! -e /tmp/linux-browser-installer* ]; then
                    cd /tmp
                    git clone https://github.com/mrclksr/linux-browser-installer.git
                fi

                chmod 755 /usr/local/sbin/debootstrap
                /tmp/linux-browser-installer/linux-browser-installer install chrome

            ;;
            "brave-linux")

                pkg_list="wget git"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
                done

                if [ ! -e /tmp/linux-browser-installer ]; then
                    cd /tmp
                    git clone https://github.com/mrclksr/linux-browser-installer.git
                fi

                chmod 755 /usr/local/sbin/debootstrap
                /tmp/linux-browser-installer/linux-browser-installer install brave

            ;;
            "edge-linux")

                pkg_list="wget git"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
                done

                if [ ! -e /tmp/linux-browser-installer* ]; then
                    cd /tmp
                    git clone https://github.com/mrclksr/linux-browser-installer.git
                fi

                chmod 755 /usr/local/sbin/debootstrap
                /tmp/linux-browser-installer/linux-browser-installer install edge

            ;;
            "opera-linux")

                pkg_list="wget git"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
                done

                if [ ! -e /tmp/linux-browser-installer* ]; then
                    cd /tmp
                    git clone https://github.com/mrclksr/linux-browser-installer.git
                fi

                chmod 755 /usr/local/sbin/debootstrap
                /tmp/linux-browser-installer/linux-browser-installer install opera

            ;;
            "vivaldi-linux")

                pkg_list="wget git"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
                done

                if [ ! -e /tmp/linux-browser-installer* ]; then
                    cd /tmp
                    git clone https://github.com/mrclksr/linux-browser-installer.git
                fi

                chmod 755 /usr/local/sbin/debootstrap
                /tmp/linux-browser-installer/linux-browser-installer install vivaldi
            ;;
            "pidgin")
                pkg_list="pidgin pidgin-bot-sentry pidgin-encryption pidgin-fetion pidgin-hotkeys
                pidgin-latex pidgin-libnotify pidgin-manualsize pidgin-otr
                pidgin-sipe pidgin-skypeweb pidgin-twitter pidgin-window_merge"

                for pkg in $pkg_list; do
                    pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
                done
            ;;
            "anydesk")
                fetch https://download.anydesk.com/freebsd/anydesk-freebsd-6.1.1-x86_64.tar.gz -P /tmp
                cd /tmp
                tar -xvzf anydesk-freebsd*
                cd anydesk-6*
                cp anydesk /usr/local/bin/
            ;;
            *)
                pkg info -e "$choice" || pkg ins -y "$choice"
            ;;
        esac
    done

    rm -f "$TMPFILE"
}

# usual tools bundle (webcams, printers, RDP, usb devices NTFS/EXFAT automount, CD/DVD burning etc.)
usual_tools_installation() {
    # Install usual tools
    TMPFILE=$(mktemp)

    bsddialog --backtitle "Select usual tools" \
        --title "Installing applications" \
        --checklist "Select usual tools:" 30 70 20 \
		"git " "Distributed source code management tool" off \
        "webcam " "Automatically configure webcam usage" off \
        "NTFS-ExFAT " "Automount USB devices with NTFS/ExFAT" off \
        "CD-DVD " "dvd+rw-tools cdrtools" off \
        "compress " "Compression/Decompression bundle" off \
        "printer " "Use printers" off \
        "wifimgr " "Manage Wifi connections" off \
		"networkmgr " "Manage Ethernet connections" off \
		"bind-tools " "Command line tools from BIND" off \
        "htop " "htop monitoring tool" off \
		"btop " "btop monitoring tool" off \
		"nano " "nano CLI editor" off \
        "hw-probe " "Send hardware probes" off \
        "inxi "  "CLI system information tool" off \
		"xrdp "  "Remote Desktop Protocol (RDP) server" off \
		"rdesktop " "RDP client for Windows" off \
		"ipfwGUI "  "IPFW firewall GUI manager" off \
        "wget " "Retrieve files by HTTP(S) or FTP" off 2>$TMPFILE

    choices=$(sed 's/"//g' < $TMPFILE | tr ' ' '\n')

    # Install the selected programs.
    for choice in $choices; do

        case $choice in
            "webcam")

				pkg_list="webcamd pwcview"

				for pkg in $pkg_list; do
						pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
				done

				sysrc webcamd_enable="YES"
				service devd restart
				pw groupmod webcamd -m "$user"
				sysrc -f /boot/loader.conf cuse_load=YES

			;;
            "NTFS-ExFAT")

				pkg_list="fuse fusefs-ntfs fusefs-exfat automount"

				for pkg in $pkg_list; do
						pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
				done

				sysrc -f /boot/loader.conf fusefs_load=YES

			;;
			"CD-DVD")

				pkg_list="dvd+rw-tools cdrtools"

				for pkg in $pkg_list; do
						pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
				done
			;;
			"compress")

				pkg_list="zip unzip bzip2 bzip3 zpaqfranz"

				for pkg in $pkg_list; do
						pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
				done
			;;
			"printer")

				pkg_list="cups cups-filters system-config-printer"

				for pkg in $pkg_list; do
						pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
				done

				sysrc cupsd_enable="YES"

			;;
			"xrdp")
				pkg_list="xrdp"

				for pkg in $pkg_list; do
						pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
				done

				sysrc xrdp_enable="NO"
    			sysrc xrdp_sesman_enable="NO"
			;;
			"ipfwGUI")
				if [ ! -x /usr/local/bin/ipfwGUI ]; then
					cd /tmp
					git clone https://github.com/bsdlme/ipfwGUI.git
					cd ipfwGUI
					make install clean
				fi
			;;
			*)
                pkg info -e "$choice" || pkg ins -y "$choice"
            ;;
        esac
    done

    rm -f "$TMPFILE"
}

# Install a hypervisor
hypervisor_selection() {
    TMPFILE=$(mktemp)

    bsddialog --backtitle "Select programs" \
            --title "Install a hypervisor" \
            --checklist "Select programs:" 9 70 20 \
            "virtualbox-ose " "VirtualBox" off \
            "BVCP " "GUI Bhyve manager" off 2>$TMPFILE

    # Read the user choices from the temporary file.
    choices=$(sed 's/"//g' < $TMPFILE | tr ' ' '\n')


    # Install the selected programs.
    for choice in $choices; do

        if [ "$choice" = "virtualbox-ose" ]; then

            pkg_list_vbox="virtualbox-ose virtualbox-ose-additions"

            for pkg in $pkg_list_vbox; do
                pkg info -e "$pkg" >/dev/null || pkg ins -y "$pkg"
            done

            sysrc vboxguest_enable=YES > /dev/null 2>&1
            sysrc vboxservice_enable=YES > /dev/null 2>&1
            sysrc vboxnet_enable=YES > /dev/null 2>&1
            sysrc -f /boot/loader.conf vboxdrv_load=YES > /dev/null 2>&1

            if ! grep -q "^\[system=10\]$" /etc/devfs.rules; then
                echo "[system=10]" >> /etc/devfs.rules
            fi

            if ! grep -q "^add path 'usb/\*' mode 0660 group operator$" /etc/devfs.rules; then
                echo "add path 'usb/*' mode 0660 group operator" >> /etc/devfs.rules
            fi

            sysrc devfs_system_ruleset="system" > /dev/null 2>&1
            pw groupmod vboxusers -m "$user"
            pw groupmod operator -m "$user"
            sysrc hald_enable=YES > /dev/null 2>&1

            if ! grep -q "^perm cd\* 0660$" /etc/devfs.conf; then
                echo "perm cd* 0660" >> /etc/devfs.conf
            fi

            if ! grep -q "^perm xpt0 0660$" /etc/devfs.conf; then
                echo "perm xpt0 0660" >> /etc/devfs.conf
            fi

            if ! grep -q "^perm pass\* 0660$" /etc/devfs.conf; then
                echo "perm pass* 0660" >> /etc/devfs.conf
            fi

            if ! grep -q "^own vboxnetctl root:vboxusers$" /etc/devfs.conf; then
                echo "own vboxnetctl root:vboxusers" >> /etc/devfs.conf
            fi

            if ! grep -q "^perm vboxnetctl 0660$" /etc/devfs.conf; then
                echo "perm vboxnetctl 0660" >> /etc/devfs.conf
            fi


            chown root:vboxusers /dev/vboxnetctl
            chmod 0660 /dev/vboxnetctl

        fi
        if [ "$choice" = "BVCP" ]; then
            fetch https://bhyve.npulse.net/release.tgz -o /tmp
            cd /tmp ; tar xvzf release.tgz ; cd bhyve-webadmin*
            ./install.sh
            printf "\n"
            echo "------------------------------------------------------"
            echo "Please note the admin password and then press [ENTER] to continue"
            echo "------------------------------------------------------"
            read ENTER
        fi
    done

    rm -f "$TMPFILE"
}

# Add $user to wheel and operator group, add wheel group to sudo permissions
password_less() {
    if bsddialog --yesno "Do you want to enable password-less root login with 'sudo su -'?" 5 68; then
        pw groupmod wheel -m "$user"
        pw groupmod operator -m "$user"
        sed -i '' "s/# %wheel/ %wheel/" /usr/local/etc/sudoers
    fi
}

# Change locale
locale_selection_menu() {

    # Utiliser bsddialog pour afficher une liste avec des boutons radio
    selected_choice=$(bsddialog --title "Select Locale" --radiolist "Please choose:" 19 50 15 \
        "af_ZA.UTF-8" "South Africa" off \
        "am_ET.UTF-8" "Ethiopia" off \
        "ar_AE.UTF-8" "United Arab Emirates" off \
        "ar_EG.UTF-8" "Egypt" off \
        "ar_JO.UTF-8" "Jordan" off \
        "ar_MA.UTF-8" "Morocco" off \
        "ar_QA.UTF-8" "Qatar" off \
        "ar_SA.UTF-8" "Saudi Arabia" off \
        "be_BY.UTF-8" "Belarus" off \
        "bg_BG.UTF-8" "Bulgaria" off \
        "ca_AD.UTF-8" "Andorra" off \
        "ca_ES.UTF-8" "Spain" off \
        "ca_FR.UTF-8" "France" off \
        "ca_IT.UTF-8" "Italy" off \
        "cs_CZ.UTF-8" "Czech Republic" off \
        "da_DK.UTF-8" "Denmark" off \
        "de_AT.UTF-8" "Austria" off \
        "de_CH.UTF-8" "Switzerland" off \
        "de_DE.UTF-8" "Germany" off \
        "el_GR.UTF-8" "Greece" off \
        "en_AU.UTF-8" "Australia" off \
        "en_CA.UTF-8" "Canada" off \
        "en_GB.UTF-8" "United Kingdom" off \
        "en_HK.UTF-8" "Hong Kong" off \
        "en_IE.UTF-8" "Ireland" off \
        "en_NZ.UTF-8" "New Zealand" off \
        "en_PH.UTF-8" "Philippines" off \
        "en_SG.UTF-8" "Singapore" off \
        "en_US.UTF-8" "United States" off \
        "en_ZA.UTF-8" "South Africa" off \
        "es_AR.UTF-8" "Argentina" off \
        "es_CR.UTF-8" "Costa Rica" off \
        "es_ES.UTF-8" "Spain" off \
        "es_MX.UTF-8" "Mexico" off \
        "et_EE.UTF-8" "Estonia" off \
        "eu_ES.UTF-8" "Spain" off \
        "fa_AF.UTF-8" "Afghanistan" off \
        "fa_IR.UTF-8" "Iran" off \
        "fi_FI.UTF-8" "Finland" off \
        "fr_BE.UTF-8" "Belgium" off \
        "fr_CA.UTF-8" "Canada" off \
        "fr_CH.UTF-8" "Switzerland" off \
        "fr_FR.UTF-8" "France" off \
        "ga_IE.UTF-8" "Ireland" off \
        "he_IL.UTF-8" "Israel" off \
        "hi_IN.UTF-8" "India" off \
        "hr_HR.UTF-8" "Croatia" off \
        "hu_HU.UTF-8" "Hungary" off \
        "hy_AM.UTF-8" "Armenia" off \
        "is_IS.UTF-8" "Iceland" off \
        "it_CH.UTF-8" "Switzerland" off \
        "it_IT.UTF-8" "Italy" off \
        "ja_JP.UTF-8" "Japan" off \
        "kk_KZ.UTF-8" "Kazakhstan" off \
        "ko_KR.UTF-8" "South Korea" off \
        "lt_LT.UTF-8" "Lithuania" off \
        "lv_LV.UTF-8" "Latvia" off \
        "mn_MN.UTF-8" "Mongolia" off \
        "nb_NO.UTF-8" "Norway" off \
        "nl_BE.UTF-8" "Belgium" off \
        "nl_NL.UTF-8" "Netherlands" off \
        "nn_NO.UTF-8" "Norway" off \
        "pl_PL.UTF-8" "Poland" off \
        "pt_BR.UTF-8" "Brazil" off \
        "pt_PT.UTF-8" "Portugal" off \
        "ro_RO.UTF-8" "Romania" off \
        "ru_RU.UTF-8" "Russia" off \
        "se_FI.UTF-8" "Finland" off \
        "se_NO.UTF-8" "Norway" off \
        "sk_SK.UTF-8" "Slovakia" off \
        "sl_SI.UTF-8" "Slovenia" off \
        "sr_RS.UTF-8" "Serbia" off \
        "sr_RS.UTF-8@latin" "Serbia" off \
        "sv_FI.UTF-8" "Finland" off \
        "sv_SE.UTF-8" "Sweden" off \
        "tr_TR.UTF-8" "Turkey" off \
        "uk_UA.UTF-8" "Ukraine" off \
        "zh_CN.UTF-8" "China" off \
        "zh_HK.UTF-8" "Hong Kong" off \
        "zh_TW.UTF-8" "Taiwan" off 3>&1 1>&2 2>&3)


    # Check and Add locale choice to /home/"$user"/.profile
	if [ ! -z $selected_choice ]; then
		if ! grep -q "export LANG=\"$selected_choice\"" /home/"$user"/.profile; then
		    {
		        echo -e "\n# CUSTOM LOCALE"
		        echo "export LANG=\"$selected_choice\""
		    } >> /home/"$user"/.profile
		fi

		if ! grep -q "export LC_CTYPE=\"$selected_choice\"" /home/"$user"/.profile; then
		    echo "export LC_CTYPE=\"$selected_choice\"" >> /home/"$user"/.profile
		fi
	fi


    # Change the locale for gdm (if installed)
    if [ -e /usr/local/etc/gdm/locale.conf ]; then
        sed -i '' "s/en_US.UTF-8/$selected_choice/" /usr/local/etc/gdm/locale.conf
    fi

    # Change Keyboard map
    kbd=$(echo "$selected_choice" | sed 's/^\(..\).*$/\1/')

    if [ ! -e /usr/local/etc/X11/xorg.conf.d/keyboard.conf ]; then

cat <<EOF > /usr/local/etc/X11/xorg.conf.d/keyboard.conf
Section "InputClass"
Identifier  "KeyboardDefaults"
    MatchIsKeyboard "on"
    Option  "XkbLayout" "$kbd"
EndSection
EOF

    fi

    build_locatedb
}

# If you use locate to search for files, then build the locatedb
build_locatedb() {
    clear
    # updatedb :
    if [ "$(sysrc -n weekly_locate_enable='/etc/periodic/weekly/310.locate')" = "YES" ]; then
        echo "The weekly locate update is already enabled in rc.conf. The script 310.locate will not run."
    else
        /etc/periodic/weekly/310.locate
    fi
}

# reboot now
reboot_now() {
    bsddialog --yesno "Thank you for using this script!\n  The installation is finished\n   Do you want to reboot now?" 7 36
    close_inac=$?

    if [ $close_inac -eq 0 ]; then
        reboot
    fi

    exit 0
}



################################################################################################################
# EXECTION FLOW

checkinternet
installpkg
welcome
check_packages_availability
update
create_boot_environment
change_repo
check_packages_availability
user_for_desktop
detect_and_clean_or_keep_existing_de  # New one !
desktop_selection_menu
autologin
automatic_graphics_detection
programs_selection_menu
usual_tools_installation
#dma
cpu_vendor
hypervisor_selection
password_less
locale_selection_menu
build_locatedb
reboot_now

