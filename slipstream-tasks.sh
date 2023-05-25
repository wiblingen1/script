#!/bin/bash

# placeholder for any slipstream tasks

# This part fully-disables read-only mode in Pi-Star and
# W0CHP-PiStar-Dash installations.
#
# 1/2023 - W0CHP (updated on 2/23/2023)
#
if grep -qo ',ro' /etc/fstab ; then
    sed -i 's/defaults,ro/defaults,rw/g' /etc/fstab
    sed -i 's/defaults,noatime,ro/defaults,noatime,rw/g' /etc/fstab
fi
if grep -qo 'remount,ro' /etc/bash.bash_logout ; then
    sed -i '/remount,ro/d' /etc/bash.bash_logout
fi
if grep -qo 'fs_mode:+' /etc/bash.bashrc ; then
    sed -i 's/${fs_mode:+($fs_mode)}//g' /etc/bash.bashrc
fi
if grep -qo 'remount,ro' /usr/local/sbin/pistar-hourly.cron ; then
    sed -i '/# Mount the disk RO/d' /usr/local/sbin/pistar-hourly.cron
    sed -i '/mount -o remount,ro/d' /usr/local/sbin/pistar-hourly.cron
fi
if grep -qo 'remount,ro' /etc/rc.local ; then
    sed -i '/remount,ro/d' /etc/rc.local
fi
if grep -qo 'remount,ro' /etc/apt/apt.conf.d/100update ; then
    sed -i '/remount,ro/d' /etc/apt/apt.conf.d/100update
fi
if grep -qo 'remount,ro' /lib/systemd/system/apt-daily-upgrade.service ; then
    sed -i '/remount,ro/d' /lib/systemd/system/apt-daily-upgrade.service
    systemctl daemon-reload 
fi
if grep -qo 'remount,ro' /lib/systemd/system/apt-daily.service ; then
    sed -i '/remount,ro/d' /lib/systemd/system/apt-daily.service
    systemctl daemon-reload 
fi
if grep -qo 'remount,ro' /etc/systemd/system/apt-daily-upgrade.service ; then
    sed -i '/remount,ro/d' /etc/systemd/system/apt-daily-upgrade.service
    systemctl daemon-reload 
fi
if grep -qo 'remount,ro' /etc/systemd/system/apt-daily.service ; then
    sed -i '/remount,ro/d' /etc/systemd/system/apt-daily.service
    systemctl daemon-reload 
fi
#

# Git URI changed when transferring repos from me to the org.
#
# 2/2023 - W0CHP
#
function gitURIupdate () {
    dir="$1"
    gitRemoteURI=$(git --work-tree=${dir} --git-dir=${dir}/.git config --get remote.origin.url)

    git --work-tree=${dir} --git-dir=${dir}/.git config --get remote.origin.url | grep 'Chipster' &> /dev/null
    if [ $? == 0 ]; then
        newURI=$( echo $gitRemoteURI | sed 's/Chipster/WPSD-Dev/' )
        git --work-tree=${dir} --git-dir=${dir}/.git remote set-url origin $newURI
    fi
}
gitURIupdate "/var/www/dashboard"
gitURIupdate "/usr/local/bin"
gitURIupdate "/usr/local/sbin"
#

# Config backup file name change, so lets address that
#
# 5/2023 W0CHP
#
if grep -q 'Pi-Star_Config_\*\.zip' /etc/rc.local ; then
    sed -i 's/Pi-Star_Config_\*\.zip/WPSD_Config_\*\.zip/g' /etc/rc.local
fi
#

# migrated from other scripts to centralize
#
# 5/2023 W0CHP
#
# cleanup legacy naming convention
if grep -q 'modemcache' /etc/rc.local ; then
    sed -i 's/modemcache/hwcache/g' /etc/rc.local
    sed -i 's/# cache modem info/# cache hw info/g' /etc/rc.local 
fi
# add hw cache to rc.local and exec
if ! grep -q 'hwcache' /etc/rc.local ; then
    sed -i '/^\/usr\/local\/sbin\/pistar-motdgen/a \\n\n# cache hw info\n\/usr\/local\/sbin\/pistar-hwcache' /etc/rc.local 
    /usr/local/sbin/pistar-hwcache
else
    /usr/local/sbin/pistar-hwcache
fi
# bullseye; change weird interface names* back to what most are accustomed to;
# <https://wiki.debian.org/NetworkInterfaceNames#THE_.22PREDICTABLE_NAMES.22_SCHEME>
# sunxi systems don't have /boot/cmdline.txt so we can ignore that.
OS_VER=$( cat /etc/debian_version | sed 's/\..*//')
if [ "${OS_VER}" -gt "10" ] && [ -f '/boot/cmdline.txt' ] && [[ ! $(grep "net.ifnames" /boot/cmdline.txt) ]] ; then
    sed -i 's/$/ net.ifnames=1 biosdevname=0/' /boot/cmdline.txt
fi
# ensure pistar-remote config has key-value pairs for new funcs (12/2/22)
if ! grep -q 'hostfiles=8999995' /etc/pistar-remote ; then
    sed -i "/^# TG commands.*/a hostfiles=8999995" /etc/pistar-remote
fi
if ! grep -q 'reconnect=8999994' /etc/pistar-remote ; then
    sed -i "/^# TG commands.*/a reconnect=8999994" /etc/pistar-remote
fi
#

# Insert missing key/values in mmdvnhost config for my custom native NextionDriver
# 
# 5/2023 W0CHP
#
# only insert the key/values IF MMDVMHost has display type of "Nextion" defined.
if [ "`sed -nr "/^\[General\]/,/^\[/{ :l /^\s*[^#].*/ p; n; /^\[/ q; b l; }" /etc/mmdvmhost | grep "Display" | cut -d= -f 2`" = "Nextion" ]; then
    # Check if the GroupsFileSrc and DMRidFileSrc exist in the INI file
    if ! grep -q "^GroupsFileSrc=" /etc/mmdvmhost; then
        # Insert GroupsFileSrc in the NextionDriver section
        sed -i '/^\[NextionDriver\]$/a GroupsFileSrc=https://hostfiles.w0chp.net/groupsNextion.txt' /etc/mmdvmhost
    fi
    # Check if GroupsFile is set to groups.txt and change it to groupsNextion.txt
    if grep -q "^GroupsFile=groups.txt" /etc/mmdvmhost; then
        sed -i 's/^GroupsFile=groups.txt$/GroupsFile=groupsNextion.txt/' /etc/mmdvmhost
    fi
fi
#

# Change default Dstar startup ref from "REF001 C" to "None", re: KC1AWV 5/21/23
#
# 5/2023 W0CHP
#
config_file="/etc/ircddbgateway"
gateway_callsign=$(grep -Po '(?<=gatewayCallsign=).*' "$config_file")
reflector1=$(grep -Po '(?<=reflector1=).*' "$config_file")
if [ "$gateway_callsign" = "M1ABC" ]; then
    new_reflector1="None"
    sed -i "s/^reflector1=.*/reflector1=$new_reflector1/" "$config_file"
fi

# fix mungeed sbin repos
#
# 5/2023 W0CHP
#if grep -q LOGNDROP /etc/iptables.rules; then
#    fwState="enabled"
#else
#    fwState="disabled"
#fi
#GIT_REPO=/usr/local/sbin
#usStr="Slipstream"
## Update the local repository
#env GIT_HTTP_CONNECT_TIMEOUT="2" env GIT_HTTP_USER_AGENT="sbin-check ${uaStr}" git -C ${GIT_REPO} fetch
## Get the timestamp of the last commit on the local repository
#LAST_COMMIT_LOCAL=$(git -C ${GIT_REPO} log -1 --format="%H" HEAD)
## Get the timestamp of the last commit on the remote repository
#LAST_COMMIT_REMOTE=$(env GIT_HTTP_CONNECT_TIMEOUT="2" env GIT_HTTP_USER_AGENT="${uaStr}" git -C ${GIT_REPO} ls-remote --exit-code --heads origin master --refs | awk '{ print $1 }')
## Check if the last commit time of the local repository is older than the last commit time of the remote repository
#if [[ "$LAST_COMMIT_LOCAL" != "$LAST_COMMIT_REMOTE" ]]; then
##    # If the local repository is older than the remote repository, reset and pull the repository
#cd /usr/local/sbin
#git remote add newrepo "$GIT_REPO" > /dev/null 2<&1
#GIT_HTTP_CONNECT_TIMEOUT="10" env GIT_HTTP_USER_AGENT="sbin-reset ${uaStr}" git fetch -q newrepo > /dev/null 2<&1
#git remote remove origin > /dev/null 2<&1
#git remote rename newrepo origin > /dev/null 2<&1
#branch="master"
#git checkout "${branch}" > /dev/null 2<&1
#git reset --hard origin/"$branch" > /dev/null 2<&1
#    if [ "$fwState" == "enabled" ]; then
#	/usr/local/sbin/pistar-system-manager -efw > /dev/null 2<&1
#    else
#	/usr/local/sbin/pistar-system-manager -dfw > /dev/null 2<&1
#    fi
#fi

