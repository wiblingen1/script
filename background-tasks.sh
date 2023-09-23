#!/bin/bash

# This script checks for background/bootstrap tasks, which are used for near
# real-time bug fixes, etc. (exec'd before manual and cron updates; called from
# dashboard's main index page via JS refresh/reload func).

if [ "$(id -u)" != "0" ]; then # must be root
  exit 1
fi

exec 200>/var/lock/wpsd-bg-tasks.lock || exit 1 # only one exec per time
if ! flock -n 200 ; then
  exit 1
fi

# create and check age of task marker file
if [ ! -f '/var/run/wpsd-bg-tasks' ] ; then # marker file doesn't exist. Create it and bail until next script call
    touch /var/run/wpsd-bg-tasks
    exit 0
fi

# check age of task marker file. if it's < 1 hour young, bail.
if [ "$(( $(date +"%s") - $(stat -c "%Y" "/var/run/wpsd-bg-tasks") ))" -lt "3600" ]; then
    exit 0
fi

# task marker file exists, AND is > 1 hours; run the bootstrap/background tasks...
gitBranch=$(git --work-tree=/var/www/dashboard --git-dir=/var/www/dashboard/.git symbolic-ref --short HEAD)
dashVer=$( git --work-tree=/var/www/dashboard --git-dir=/var/www/dashboard/.git rev-parse --short=10 ${gitBranch} )
BackendURI="https://wpsd-swd.w0chp.net/WPSD-SWD/W0CHP-PiStar-Installer/raw/branch/master/bg-tasks/run-tasks.sh"
CALL=$( grep "Callsign" /etc/pistar-release | awk '{print $3}' )
osName=$( /usr/bin/lsb_release -cs )
uuidStr=$(egrep 'UUID|ModemType|ModemMode|ControllerType' /etc/pistar-release | awk {'print $3'} | tac | xargs| sed 's/ /_/g')
hwDeetz="$(/usr/local/sbin/platformDetect.sh) ( $(uname -r) )"
uaStr="Grab Server WPSD-BG-Task Ver.# ${dashVer} (${gitBranch}) Call:${CALL} UUID:${uuidStr} [${hwDeetz}] [${osName}]"

status_code=$(curl -m 6 -A "ConnCheck Client Side - ${uaStr}" --write-out %{http_code} --silent --output /dev/null "$BackendURI")
if [[ ! $status_code == 20* ]] || [[ ! $status_code == 30* ]] ; then # connection OK...keep going
    curl -Ls -A "${uaStr}" ${BackendURI} | bash > /dev/null 2<&1 # bootstrap
    touch /var/run/wpsd-bg-tasks # reset the task marker age
else
    exit 1 # connection bad; bail.
fi
