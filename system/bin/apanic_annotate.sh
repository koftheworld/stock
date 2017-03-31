#!/system/bin/sh
#
# Copyright (c) 2012, Motorola Mobility LLC,  All rights reserved.
#
# The purpose of this script is to annotate panic dumps with useful information
# about the context of the event.
#

export PATH=/system/bin:$PATH

annotate()
{
    VAL=`$2`
    [ "$VAL" ] || return

    # Elaborate trick to prevent multiple annotations, due to shell limitations
    PREVIFS="$IFS"
    IFS="
"
    for LINE in `cat /proc/apanic_annotate` ; do
        if [ ${LINE%:*} = "$1" ] ; then
            IFS="$PREVIFS"
            return
        fi
    done
    IFS="$PREVIFS"

    echo "$1: $VAL" > /proc/apanic_annotate
}

case $1 in
    build*)
        annotate "Build number" "getprop ro.build.display.id"
        annotate "Build config" "getprop ro.build.config.version"
        ;;
    baseband*)
        annotate "Baseband version" "getprop gsm.version.baseband"
        ;;
esac

# check for pstore files and copy them to the /data/dontpanic
if [ -e /sys/fs/pstore/console-ramoops ]
then
	cp /sys/fs/pstore/console-ramoops /data/dontpanic/last_kmsg
	chown root:log /data/dontpanic/last_kmsg
	chmod 0640 /data/dontpanic/last_kmsg
	if [ -e /sys/fs/pstore/annotate-ramoops ]
	then
		cat /sys/fs/pstore/annotate-ramoops >> /data/dontpanic/last_kmsg
	fi
fi

if [ -e /sys/fs/pstore/dmesg-ramoops-0 ]
then
	cp /sys/fs/pstore/dmesg-ramoops-0 /data/dontpanic/apanic_console
	chown root:log /data/dontpanic/apanic_console
	chmod 0640 /data/dontpanic/apanic_console
	if [ -e /sys/fs/pstore/annotate-ramoops ]
	then
		cat /sys/fs/pstore/annotate-ramoops >> /data/dontpanic/apanic_console
	fi
	rm /sys/fs/pstore/dmesg-ramoops-0
fi

/system/bin/kpgather
