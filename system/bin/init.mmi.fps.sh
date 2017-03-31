#!/system/bin/sh
#
#Provision the sensor. This is a one time operation
#This is a temporary solution and will need to be removed once
#sensors is correctly provisioned in the factory.
./system/bin/vfmProvision
# Take ownership of the sensor. This is a workaround until this is done in the factory
./system/bin/vfsSecMgmt -s
