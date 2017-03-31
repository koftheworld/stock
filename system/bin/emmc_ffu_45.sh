#!/system/bin/sh
#
# Copyright (c) 2013-2015, Motorola LLC  All rights reserved.
#

SCRIPT=${0#/system/bin/}

MID=`cat /sys/block/mmcblk0/device/manfid`
if [ "$MID" != "0x000045" ] ; then
  echo "Result: FAIL"
  echo "$SCRIPT: manufacturer not supported" > /dev/kmsg
  exit
fi
echo "Manufacturer: Sandisk"

# Skip anything other than this model of Sandisk eMMC
PNM=`cat /sys/block/mmcblk0/device/name`
if [ "$PNM" != "SDW32G" -a "$PNM" != "SDW64G" ] ; then
  echo "Device Name: $PNM"
  echo "Result: PASS"
  echo "$SCRIPT: no action required" > /dev/kmsg
  exit
fi

echo "Device Name: $PNM"

CID=`cat /sys/block/mmcblk0/device/cid`
PRV=${CID:18:2}
echo "Product Revision: $PRV"

# Sandisk stores FW version as a space-padded ASCII string, which has to be
# corrected for endianness since the field is a 64-bit integer.
FIRMWARE_VERSION=`cat /sys/block/mmcblk0/device/firmware_version`
FIRMWARE_VERSION=${FIRMWARE_VERSION#0x}
POS=${#FIRMWARE_VERSION}
while [ $POS -gt 0 ] ; do
  POS=$((POS - 2))
  CHAR=`echo \\\x${FIRMWARE_VERSION:$POS:2}`
  [ "$CHAR" != " " ] && FW="$FW$CHAR"
done
echo "Firmware Version: $FW"

if [ "$FW" == "CS1.0B" ] ; then
  echo "Result: PASS"
  echo "$SCRIPT: firmware already updated" > /dev/kmsg
  exit
fi

# Flash the firmware
echo "Starting upgrade..."
sync
/system/bin/emmc_ffu -yR
STATUS=$?

if [ "$STATUS" != "0" ] ; then
  echo "Result: FAIL"
  echo "$SCRIPT: firmware update failed ($STATUS)" > /dev/kmsg
  exit
fi

sleep 1
CID=`cat /sys/block/mmcblk0/device/cid`
PRV=${CID:18:2}
echo "New Product Revision: $PRV"

FIRMWARE_VERSION=`cat /sys/block/mmcblk0/device/firmware_version`
FIRMWARE_VERSION=${FIRMWARE_VERSION#0x}
FW=
POS=${#FIRMWARE_VERSION}
while [ $POS -gt 0 ] ; do
  POS=$((POS - 2))
  CHAR=`echo \\\x${FIRMWARE_VERSION:$POS:2}`
  [ "$CHAR" != " " ] && FW="$FW$CHAR"
done
echo "New Firmware Version: $FW"

if [ "$FW" != "CS1.0B" ] ; then
  echo "Result: FAIL"
  echo "$SCRIPT: firmware update failed ($FW)" > /dev/kmsg
  exit
fi

echo "Result: PASS"
echo "$SCRIPT: firmware updated successfully" > /dev/kmsg
