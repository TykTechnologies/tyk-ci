#!/bin/sh

include(header.m4)

# Step 1, decide if we should use systemd or init/upstart
use_systemctl="True"
systemd_version=0
if ! command -V systemctl >/dev/null 2>&1; then
    use_systemctl="False"
else
    systemd_version=$(systemctl --version | head -1 | sed 's/systemd //g')
fi

cleanup() {
    # After installing, remove files that were not needed on this platform / system
    if [ "${use_systemctl}" = "False" ]; then
        rm -f /lib/systemd/system/xCOMPATIBILITY_NAME.service
    else
        rm -f /etc/init.d/xCOMPATIBILITY_NAME
    fi
}

restoreSystemd() {
    if [ "${use_systemctl}" = "True" ]; then
        if [ ! -f /lib/systemd/system/xCOMPATIBILITY_NAME.service ]; then
            cp /opt/xCOMPATIBILITY_NAME/install/xCOMPATIBILITY_NAME.service /lib/systemd/system/xCOMPATIBILITY_NAME.service
        fi
    fi
}

cleanInstall() {
    printf "\033[32m Post Install of an clean install\033[0m\n"
    # Step 3 (clean install), enable the service in the proper way for this platform
    if [ "${use_systemctl}" = "False" ]; then
        if command -V chkconfig >/dev/null 2>&1; then
            chkconfig --add xCOMPATIBILITY_NAME
	    chkconfig xCOMPATIBILITY_NAME on
        fi
        if command -V update-rc.d >/dev/null 2>&1; then
            update-rc.d xCOMPATIBILITY_NAME defaults
        fi

        service xCOMPATIBILITY_NAME restart ||:
    else
        # rhel/centos7 cannot use ExecStartPre=+ to specify the pre start should be run as root
        # even if you want your service to run as non root.
        if [ "${systemd_version}" -lt 231 ]; then
            printf "\033[31m systemd version %s is less then 231, fixing the service file \033[0m\n" "${systemd_version}"
            sed -i "s/=+/=/g" $SYSTEMD/xCOMPATIBILITY_NAME.service
        fi
        printf "\033[32m Reload the service unit from disk\033[0m\n"
        systemctl daemon-reload ||:
        printf "\033[32m Unmask the service\033[0m\n"
        systemctl unmask xCOMPATIBILITY_NAME ||:
        printf "\033[32m Set the preset flag for the service unit\033[0m\n"
        systemctl preset xCOMPATIBILITY_NAME ||:
        printf "\033[32m Set the enabled flag for the service unit\033[0m\n"
        systemctl enable xCOMPATIBILITY_NAME ||:
        systemctl restart xCOMPATIBILITY_NAME ||:
    fi
}

upgrade() {
    printf "\033[32m Post Install of an upgrade\033[0m\n"
    if [ "${use_systemctl}" = "False" ]; then
	systemctl daemon-reload ||:
	systemctl restart xCOMPATIBILITY_NAME ||:
    else
	service xCOMPATIBILITY_NAME restart
    fi
}

# Step 2, check if this is a clean install or an upgrade
action="$1"
if  [ "$1" = "configure" ] && [ -z "$2" ]; then
    # Alpine linux does not pass args, and deb passes $1=configure
    action="install"
elif [ "$1" = "configure" ] && [ -n "$2" ]; then
    # deb passes $1=configure $2=<current version>
    action="upgrade"
fi

case "$action" in
    "1" | "install")
	cleanInstall
	;;
    "2" | "upgrade")
	printf "\033[32m Post Install of an upgrade\033[0m\n"
       restoreSystemd
       upgrade
	;;
    *)
	# $1 == version being installed
	printf "\033[32m Alpine\033[0m"
	cleanInstall
	;;
esac

# From https://www.debian.org/doc/debian-policy/ap-flowcharts.html and
# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/ it appears that cleanup is not
# needed to support systemd and sysv

#cleanup
