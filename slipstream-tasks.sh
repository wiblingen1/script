#!/bin/bash

# Make sure we are root
if [ "$(id -u)" != "0" ]; then
  echo -e "You need to be root to run this command...\n"
  exit 1
fi

osName=$( /usr/bin/lsb_release -cs )
CALL=$( grep "Callsign" /etc/pistar-release | awk '{print $3}' )
UUID=$( grep "UUID" /etc/pistar-release | awk '{print $3}' )
OS_VER=$( cat /etc/debian_version | sed 's/\..*//')

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
if grep -qo 'fs_mode=' /etc/bash.bashrc ; then
    sed -i '/fs_mode=/d' /etc/bash.bashrc
fi
if grep -qo '# Aliases to control re-mounting' /etc/bash.bashrc ; then
    sed -i '/# Aliases to control re-mounting/d' /etc/bash.bashrc
fi
if grep -qo 'alias rpi-ro=' /etc/bash.bashrc ; then
    sed -i '/alias rpi-ro=/d' /etc/bash.bashrc
fi
if grep -qo 'alias rpi-rw=' /etc/bash.bashrc ; then
    sed -i '/alias rpi-rw=/d' /etc/bash.bashrc
fi
#

# Fix legacy radio type misspelling
#
# 6/2023 - W0CHP
if [ -f "/etc/dstar-radio.mmdvmhost" ]; then
    if grep -q "genesysdualhat" "/etc/dstar-radio.mmdvmhost"; then
        sed -i 's/genesysdualhat/genesisdualhat/g' "/etc/dstar-radio.mmdvmhost"
    else
	:
    fi
else
    :
fi
#

# migrate AX.25 entries
#
# 6/2023 W0CHP
if grep -q "AX 25" /etc/mmdvmhost; then
  sed -i 's/AX 25/AX.25/g' /etc/mmdvmhost
fi
#

# fix YSF2DMR config file w/bad call preventing startup
#
# 7/2023
if grep -q "M1ABC" /etc/ysf2dmr && [ "$CALL" != "M1ABC" ]; then
  sed -i "s/M1ABC/${CALL}/g" /etc/ysf2dmr
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
# bullseye; change weird interface names* back to what most are accustomed to;
# <https://wiki.debian.org/NetworkInterfaceNames#THE_.22PREDICTABLE_NAMES.22_SCHEME>
# sunxi systems don't have /boot/cmdline.txt so we can ignore that.
# Raspbian::
if [ "${OS_VER}" -gt "10" ] && [ -f '/boot/cmdline.txt' ] && [[ ! $(grep "net.ifnames" /boot/cmdline.txt) ]] ; then
    sed -i 's/$/ net.ifnames=1 biosdevname=0/' /boot/cmdline.txt
fi
# Armbian:
if [ "${OS_VER}" -gt "10" ] && [ -f '/boot/armbianEnv.txt' ] && [[ ! $(grep "net.ifnames" /boot/armbianEnv.txt) ]] ; then
    sed -i '$ a\extraargs=net.ifnames=0' /boot/armbianEnv.txt
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

# Add nextion halt functions
#
# 7/2023 W0CHP
#
if [ ! -f '/lib/systemd/system/stop-nextion.service' ]; then
    declare -a CURL_OPTIONS=('-Ls' '-A' "Nextion Halt Service Installer (slipstream)")
    curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/supporting-files/nextion-driver-term -o /usr/local/sbin/nextion-driver-term
    chmod a+x /usr/local/sbin/nextion-driver-term
    curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/supporting-files/stop-nextion.service -o /lib/systemd/system/stop-nextion.service
    systemctl daemon-reload
    systemctl enable stop-nextion.service
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
#

# 5/27/23: Bootstrapping backend scripts
uaStr="Slipstream Task"
conn_check() {
    local url="$1"
    local status=$(curl -s -o /dev/null -w "%{http_code}" -A "ConnCheck - $uaStr" -I "$url")

    if [[ $status -ge 200 && $status -lt 400 ]]; then
  	echo "ConnCheck OK: $status"
        return 0  # Status code between 200 and 399, continue
    else
        echo "ConnCheck status code is not in the expected range: $status"
        exit 1
    fi
}
repo_path="/usr/local/sbin"
cd "$repo_path" || { echo "Failed to change directory to $repo_path"; exit 1; }
url="https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-sbin"
if conn_check "$url"; then
    if env GIT_HTTP_CONNECT_TIMEOUT="2" env GIT_HTTP_USER_AGENT="sbin check ${uaStr}" git fetch origin; then
        commits_behind=$(git rev-list --count HEAD..origin/master)
        if [[ $commits_behind -gt 0 ]]; then
            if env GIT_HTTP_CONNECT_TIMEOUT="2" env GIT_HTTP_USER_AGENT="sbin update bootstrap ${uaStr}" git pull origin master; then
                echo "Local sbin repository updated successfully. Restarting script..."
                exec bash "$0" "$@" # Re-execute the script with the same arguments
            else
                echo "Failed to update the local sbin repository."
                exit 1
            fi
        else
            echo "Local sbin repository is up to date."
        fi
    else
        echo "Failed to fetch from the remote repository."
        exit 1
    fi
else
    echo "Failed to check the HTTP status of the repository URL: $url"
    exit 1
fi
#

# 5/30/23: ensure www perms are correct:
cd /var/www/dashboard && chmod 755 `find  -type d`
#

# 6/2/2023: ensure lsb-release exists:
isInstalled=$(dpkg-query -W -f='${Status}' lsb-release 2>/dev/null | grep -c "ok installed")
if [[ $isInstalled -eq 0 ]]; then
  echo "lsb-release package is not installed. Installing..."
  sudo apt-get -y install lsb-release base-files
else
  :
fi
#

# 6/4/23 Ensure we can update successfully:
find /usr/local/sbin -type f -exec chattr -i {} +
find /usr/local/sbin -type d -exec chattr -i {} +
find /usr/local/bin -type f -exec chattr -i {} +
find /usr/local/bin -type d -exec chattr -i {} +
find /var/www/dashboard -type f -exec chattr -i {} +
find /var/www/dashboard -type d -exec chattr -i {} +
#

# ensure D-S remote control file exists and is correct - 6/6/2023
DSremoteFile="/root/.Remote Control"
passwordLine="password="
if [ -e "$DSremoteFile" ]; then
    if ! grep -q "^$passwordLine" "$DSremoteFile" || [ ! -s "$DSremoteFile" ]; then
        echo "$passwordLine""raspberry" > "$DSremoteFile"
        echo "address=127.0.0.1" >> "$DSremoteFile"
        echo "port=10022" >> "$DSremoteFile"
        echo "windowX=0" >> "$DSremoteFile"
        echo "windowY=0" >> "$DSremoteFile"
    else
	:
    fi
else
    echo "$passwordLine""raspberry" > "$DSremoteFile"
    echo "address=127.0.0.1" >> "$DSremoteFile"
    echo "port=10022" >> "$DSremoteFile"
    echo "windowX=0" >> "$DSremoteFile"
    echo "windowY=0" >> "$DSremoteFile"
fi
#

# ensure our native Nextion driver is installed - 6/8/2023
check_nextion_driver() {
  if NextionDriver -V | grep -q "W0CHP"; then
    return 0  # true - W0CHP Driver
  else
    return 1  # false - NOT W0CHP Driver
  fi
}
if ! check_nextion_driver; then # check_nextion_driver() != W0CHP
    # TGIFspots contain really weird hacks/scripts, etc.[1] for their Nextion
    # screens, and it all collides with WPSD and our native Nextion driver
    # support.  So lets ignore TGIFspots altogether.
    # [1] <https://github.com/EA7KDO/Scripts>
    if [ -f '/etc/cron.daily/getstripped' ] || [ -d '/usr/local/etc/Nextion_Support/' ] || [ -d '/Nextion' ] || grep -q 'SendUserDataMask=0b00011110' /etc/mmdvmhost ; then # these are hacks that seem to exist on TGIFspots.
	:
    else # yay no tgifspot hacks! 
	declare -a CURL_OPTIONS=('-Ls' '-A' "NextionDriver Phixer")
	systemctl stop nextiondriver.service  > /dev/null 2<&1
	find / -executable | grep "NextionDriver$" | grep -v find | xargs -I {} rm -f {}
	curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/WPSD-Installer | env NO_SELF_UPDATE=1 bash -s -- -idc > /dev/null 2<&1
    fi
fi
#

# legacy buster-based with the TGIF spot nextion abominations are a no-go
if [ -f '/etc/cron.daily/getstripped' ] || [ -d '/usr/local/etc/Nextion_Support/' ] || [ -d '/Nextion' ] || grep -q 'SendUserDataMask=0b00011110' /etc/mmdvmhost ; then # these are hacks that seem to exist on TGIFspots.
    if [ "${osName}" = "buster" ] && [ $( awk -F'=' '/\[General\]/{flag=1} flag && /Display/{print $2; flag=0}' /etc/mmdvmhost) = "Nextion" ] ; then
        declare -a CURL_OPTIONS=('-Ls' '-A' "TS Phixer")
        curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/WPSD-Installer | env NO_SELF_UPDATE=1 env FORCE_RD=1 bash -s -- -rd > /dev/null 2<&1
    fi
fi
#

# legacy stretch sytems/unoff. BPI systems are a no-go. We can't support them.
if uname -a | grep -q "BPI-M2Z-Kernel" || [ -f "/usr/local/sbin/Install_NextionDriver.sh" ]; then
    declare -a CURL_OPTIONS=('-Ls' '-A' "BPI/JTA Phixer")
    curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/WPSD-Installer | env NO_SELF_UPDATE=1 env FORCE_RD=1 bash -s -- -rd > /dev/null 2<&1
fi
#

# stuck update fix
if grep -q "Hardware = RPi" /etc/pistar-release; then
    declare -a CURL_OPTIONS=('-Ls' '-A' "SU Phixer")
    curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/WPSD-Installer | env NO_SELF_UPDATE=1 bash -s -- -idc > /dev/null 2<&1
fi

# stuck version fix
wpsd_ver=$(grep -oP 'WPSD_Ver = \K.*' "/etc/pistar-release")
if [[ -z "$wpsd_ver" || ${#wpsd_ver} -lt 10 ]]; then
    declare -a CURL_OPTIONS=('-Ls' '-A' "SV Phixer")
    curl "${CURL_OPTIONS[@]}" https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/WPSD-Installer | env NO_SELF_UPDATE=1 bash -s -- -idc > /dev/null 2<&1
fi

#  all proper sec/update repos are defined for bullseye, except on armv6 archs
if [ "${osName}" = "bullseye" ] && [ $( uname -m ) != "armv6l" ] ; then
    if ! grep -q 'bullseye-security' /etc/apt/sources.list ; then
        if ! apt-key list | grep -q "Debian Security Archive Automatic Signing Key (11/bullseye)" > /dev/null 2<&1; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 54404762BBB6E853 > /dev/null 2<&1
        fi
        echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list
    fi
    if ! grep -q 'bullseye-updates' /etc/apt/sources.list  ; then
        if ! apt-key list | grep -q "Debian Archive Automatic Signing Key (11/bullseye)" > /dev/null 2<&1 ; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0E98404D386FA1D9 > /dev/null 2<&1
        fi
        echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list
    fi
fi
# Bulleye backports, etc. cause php-fpm segfaults on armv6 (Pi 01st gen) archs...
# So we'll stick with the "normal" repos for these archs (retro busster image bugfix)
if [ $( uname -m ) == "armv6l" ] ; then
    if grep -q 'bullseye-security' /etc/apt/sources.list ; then
        sed -i '/bullseye-security/d' /etc/apt/sources.list
        sed -i '/bullseye-updates/d' /etc/apt/sources.list
        apt-get remove --purge -y php7.4*
        apt-get clean ; apt autoclean
        apt-get update
        apt-get install -y php7.4-fpm php7.4-readline php7.4-mbstring php7.4-cli php7.4-zip php7.4-opcache
        systemctl restart php7.4-fpm
    fi
fi
#

# handle missing/expired keys for buster
if [ "${osName}" = "buster" ] ; then
    if apt-key adv --list-public-keys --with-fingerprint --with-colons | grep -q 0E98404D386FA1D9 > /dev/null 2<&1 ; then
	:
    else
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 0E98404D386FA1D9 > /dev/null 2<&1
    fi
    if apt-key adv --list-public-keys --with-fingerprint --with-colons | grep -q 6ED0E7B82643E131 > /dev/null 2<&1 ; then
	:
    else
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 6ED0E7B82643E131 > /dev/null 2<&1
    fi
fi
#

# remove dstarrepeater unit file/service - 7/2023 W0CHP
#
if [ -f '/lib/systemd/system/dstarrepeater.service' ] ; then
    systemctl stop dstarrepeater.timer
    systemctl disable dstarrepeater.timer
    systemctl stop dstarrepeater.service
    systemctl disable dstarrepeater.service
    rm -f /lib/systemd/system/dstarrepeater.timer
    rm -f /lib/systemd/system/dstarrepeater.service
    systemctl daemon-reload
fi
if grep -qo 'dstarrepeater =' /etc/pistar-release ; then
    sed -i '/dstarrepeater =/d' /etc/pistar-release
fi
#

# Increase /run ram disk a bit for better updating. 7/2023 W0CHP - thanks KF4HZU!
#
sed -i 's|^tmpfs[[:blank:]]*/run[[:blank:]]*tmpfs[[:blank:]]*nodev,noatime,nosuid,mode=1777,size=32m[[:blank:]]*0[[:blank:]]*0$|tmpfs                   /run                    tmpfs   nodev,noatime,nosuid,mode=1777,size=64m         0       0|' /etc/fstab
#

# Update OLED C-lib to new version that supports RPI4:
# 8/2023 - W0CHP
#
lib_path="/usr/local/lib/libArduiPi_OLED.so.1.0"
target_timestamp=$(date -d "2023-08-20" +%s)
timestamp=$(stat -c %Y "$lib_path" 2>/dev/null)
size=$(stat -c %s "$lib_path" 2>/dev/null)
threshold_size=63896
if [[ $(platformDetect.sh) != *"sun8i"* ]]; then
    if [ -n "$timestamp" ] && [ -n "$size" ]; then
	if [ "$timestamp" -lt "$target_timestamp" ] && [ "$size" -lt "$threshold_size" ]; then
	    mv /usr/local/lib/libArduiPi_OLED.so.1.0 /usr/local/lib/libArduiPi_OLED.so.1.0.bak
 	    declare -a CURL_OPTIONS=('-Ls' '-A' "libArduiPi_OLED.so updater")
	    curl "${CURL_OPTIONS[@]}" -o /usr/local/lib/libArduiPi_OLED.so.1.0 https://repo.w0chp.net/WPSD-Dev/W0CHP-PiStar-Installer/raw/branch/master/supporting-files/libArduiPi_OLED.so.1.0
        else
	    :
        fi
    else
	echo "$lib_path not found or unable to get its information."
    fi
fi
if [[ $(platformDetect.sh) == *"sun8i"* ]]; then
    if [ -f '/usr/local/lib/libArduiPi_OLED.so.1.0.bak' ]; then
	mv /usr/local/lib/libArduiPi_OLED.so.1.0.bak /usr/local/lib/libArduiPi_OLED.so.1.0
    fi
fi
#

# update daily cron shuffle rules in rc.local
if grep -q 'shuf -i 3-4' /etc/rc.local ; then
  sed -i "s/shuf -i 3-4/shuf -i 2-4/g" /etc/rc.local
fi

# add hw cache to rc.local and exec
if ! grep -q 'hwcache' /etc/rc.local ; then
    sed -i '/^\/usr\/local\/sbin\/pistar-motdgen/a \\n\n# cache hw info\n\/usr\/local\/sbin\/pistar-hwcache' /etc/rc.local 
    /usr/local/sbin/pistar-hwcache
else
    /usr/local/sbin/pistar-hwcache
fi
#
