#! /bin/bash
#
# Return the version of the Raspberry Pi or other clone boards
# Written by Andy Taylor (MW0MWZ)
# Enhanced by W0CHP
#
# Pi Rev codes available at <https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-revision-codes>

# Pull the CPU Model from /proc/cpuinfo
modelName=$( lscpu | grep Architecture | sed 's/.*: //' | sed -e 's/^[ \t]*//' )
hardwareField=$(grep 'Hardware' /proc/cpuinfo | sed 's/.*: //')
arch=$(uname -m)

if [ -f /proc/device-tree/model ]; then
    raspberryModel=$(tr -d '\0' </proc/device-tree/model | sed 's/Rev/Rev./')
fi

if [[ ${modelName} == "arm"* ]] || [[ ${modelName} == "aarch"* ]]; then
    # Pull the Board revision from /proc/cpuinfo
    boardRev=$(grep 'Revision' /proc/cpuinfo | awk '{print $3}' | sed 's/^100//')
    # Grab actual model name as well...as a fallback to $raspberryModel: /proc/device-tree/model
    actualModel=$(grep 'Model' /proc/cpuinfo| cut -d' ' -f2- | sed 's/Rev/Rev./')

    # Make the board revision human readable
    case $boardRev in
        # old-style rev. nos.:
        *0002) raspberryVer="256MB";;
        *0003) raspberryVer="+ ECN0001 no fuses, D14 removed 256MB";;
        *0004) raspberryVer="256MB";;
        *0005) raspberryVer="256MB";;
        *0006) raspberryVer="256MB";;
        *0007) raspberryVer="Mounting holes 256MB";;
        *0008) raspberryVer="Mounting holes 256MB";;
        *0009) raspberryVer="Mounting holes 256MB";;
        *000d) raspberryVer="512MB";;
        *000e) raspberryVer="512MB";;
        *000f) raspberryVer="512MB";;
        *0010) raspberryVer="512MB";;
        *0011) raspberryVer="512MB";;
        *0012) raspberryVer="256MB";;
        *0013) raspberryVer="512MB";;
        *0014) raspberryVer="512MB";;
        *0015) raspberryVer="";;
        # new-style rev. nos.:
        *900021) raspberryVer="512MB - Sony UK";;
        *900032) raspberryVer="512MB - Sony UK";;
        *900092) raspberryVer="512MB - Sony UK";;
        *900093) raspberryVer="512MB - Sony UK";;
        *902120) raspberryVer="512MB - Sony UK";;
        *9000c1) raspberryVer="512MB - Sony UK";;
        *9020e0) raspberryVer="512MB - Sony UK";;
        *920092) raspberryVer="512MB - Embest China";;
        *920093) raspberryVer="512MB - Embest China";;
        *900061) raspberryVer="512MB - Sony UK";;
        *a01040) raspberryVer="1GB - Sony UK";;
        *a01041) raspberryVer="1GB - Sony UK";;
        *a02082) raspberryVer="1GB - Sony UK";;
        *a020a0) raspberryVer="1GB - Sony UK";;
        *a020d3) raspberryVer="1GB - Sony UK";;
        *a02042) raspberryVer="1GB - Sony UK";;
        *a21041) raspberryVer="1GB - Embest China";;
        *a22042) raspberryVer="1GB - Embest China";;
        *a22082) raspberryVer="1GB - Embest China";;
        *a220a0) raspberryVer="1GB - Embest China";;
        *a32082) raspberryVer="1GB - Sony Japan";;
        *a52082) raspberryVer="1GB - Stadium China";;
        *a22083) raspberryVer="1GB - Embest China";;
        *a02100) raspberryVer="1GB - Sony UK";;
        *a03111) raspberryVer="1GB - Sony UK";;
        *b03111) raspberryVer="2GB - Sony UK";;
        *b03114) raspberryVer="2GB - Sony UK";;
        *c03111) raspberryVer="4GB - Sony UK";;
        *c03114) raspberryVer="4GB - Sony UK";;
        *b03115) raspberryVer="4GB - Sony UK";;
        *c03115) raspberryVer="4GB - Sony UK";;
        *b03112) raspberryVer="2GB - Sony UK";;
        *c03112) raspberryVer="4GB - Sony UK";;
        *d03114) raspberryVer="8GB - Sony UK";;
        *d03115) raspberryVer="8GB - Sony UK";;
        *c03130) raspberryVer="4GB - Sony UK";;
        *a03140) raspberryVer="CM4 Rev 1.0 1GB";;
        *b03140) raspberryVer="CM4 Rev 1.0 2GB";;
        *c03140) raspberryVer="CM4 Rev 1.0 4GB";;
        *d03140) raspberryVer="CM4 Rev 1.0 8GB";;
        *) raspberryVer="ARM-based System";;
    esac

    if [[ ${hardwareField} == "ODROID"* ]]; then
        echo "Odroid XU3/XU4 System"
    elif [[ ${hardwareField} == *"sun8i"* ]]; then
	clone_board=$(tr -d '\0' </proc/device-tree/model)
	if [ ! -z "${clone_board}" ]; then
	    echo "$clone_board, sun8i"
	else
	    echo "sun8i-based Pi Clone"
	fi
    elif [[ ${hardwareField} == *"s5p4418"* ]]; then
        echo "Samsung Artik"
    elif [[ ${raspberryModel} == "Raspberry"* ]]; then
	raspberryModel=$(echo $raspberryModel) 
	echo "${raspberryModel} ${arch} ${raspberryVer} - Board # $boardRev"
    else
	echo "$actualModel $arch $raspberryVer"
    fi
    
elif [[ ${hardwareField} == *"sun8i"* ]]; then
    echo "sun8i-based Pi Clone"
else
    echo "Generic "`uname -p`" class computer"
fi

