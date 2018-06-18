#!/bin/bash
#
# vpn-up.sh - automates bringing up a VPN over Docker on an Amazon Linux AMI
#

EC2_SECURITY_GROUP_ID="XXX"
AMI_ID="YYY"

# Get the current lowest price for the machine we want (we'll be bidding a cent above)
echo -n "Getting lowest t2.micro bid... "
PRICE_AND_ZONE=($( aws ec2 describe-spot-price-history --instance-types t2.micro --start-time `date +%s` | jq --raw-output '.SpotPriceHistory|=sort_by(.SpotPrice)|first(.SpotPriceHistory[].SpotPrice), first(.SpotPriceHistory[].AvailabilityZone)'))
PRICE=${PRICE_AND_ZONE[0]}
ZONE=${PRICE_AND_ZONE[1]}
echo $PRICE

echo -n "Creating spot instance request... "
SPOT_INSTANCE_ID=$( aws ec2 request-spot-instances --spot-price $( bc <<< "$PRICE + 0.01" ) --launch-specification "
  {
    \"SecurityGroupIds\": [\"$EC2_SECURITY_GROUP_ID\"],
    \"ImageId\": \"$AMI_ID\",
    \"InstanceType\": \"t2.micro\"
  }" | jq --raw-output '.SpotInstanceRequests[0].SpotInstanceRequestId' )
echo $SPOT_INSTANCE_ID

echo -n "Waiting for instance to be launched... "
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids "$SPOT_INSTANCE_ID"

INSTANCE_ID=$( aws ec2 describe-spot-instance-requests --spot-instance-request-ids "$SPOT_INSTANCE_ID" | jq --raw-output '.SpotInstanceRequests[0].InstanceId' )
echo "$INSTANCE_ID"

echo "Removing the spot instance request..."
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids "$SPOT_INSTANCE_ID" > /dev/null

echo -n "Getting ip address... "
IP=$( aws ec2 describe-instances --instance-ids "$INSTANCE_ID" | jq --raw-output '.Reservations[0].Instances[0].PublicIpAddress' )
echo "$IP"

echo "Waiting for server to become available..."
while ! ping -c 1 -n -W 1 $IP &> /dev/null
do
    printf "%c" "."
done
echo -e "\nServer is now online... "

echo "Waiting 10s for SSH to be up..."

sleep 10

echo -e "\nSSHing to this server to install the vpn... "

ssh-keyscan -H $IP >> ~/.ssh/known_hosts

ssh ec2-user@$IP sudo docker pull kylemanna/openvpn

ssh ec2-user@$IP sudo docker run -v ovpn-data:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u udp://$IP

ssh ec2-user@$IP sudo docker run -v ovpn-data:/etc/openvpn --log-driver=none --rm -i kylemanna/openvpn ovpn_initpki nopass

ssh ec2-user@$IP sudo docker run -v ovpn-data:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

ssh ec2-user@$IP sudo docker run -v ovpn-data:/etc/openvpn --log-driver=none --rm -i kylemanna/openvpn easyrsa build-client-full client nopass

ssh ec2-user@$IP "sudo docker run -v ovpn-data:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient client > client.ovpn"

scp ec2-user@$IP:~/client.ovpn ~/

echo "All done!"
