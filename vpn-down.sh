#!/bin/bash

# Verify that the instance actually exists (and that there's only one)
# instance-state-code 16 means running
echo -n "Finding your instance... "
INSTANCES=$( aws ec2 describe-instances --filters Name=instance-state-code,Values=16 Name=instance-type,Values=t2.micro)
if [ $( echo "$INSTANCES" | jq '.Reservations | length' ) -ne "1" ]; then
	echo "didnt find exactly one instance!"
	exit
fi
INSTANCE_ID=$( echo "$INSTANCES" | jq --raw-output '.Reservations[0].Instances[0].InstanceId' )
echo "$INSTANCE_ID"

# Terminate the instance
echo "Terminating instance..."
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" > /dev/null

echo "All done!"
