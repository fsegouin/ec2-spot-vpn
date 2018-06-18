# ec2-spot-vpn
Quickly create a VPN anywhere in the world using EC2 Spot Instances.
Inspired by an article from [Larry Gadea](https://lg.io/2015/07/05/revised-and-much-faster-run-your-own-highend-cloud-gaming-service-on-ec2.html).
The VPN used here is a Docker image made by [Kyle Manna](https://github.com/kylemanna/docker-openvpn).

This is obviously not secure (certs generated without a passphrase) and meant to be used as a proof of concept only.

## Prerequisites

* AWS CLI tool already configured (use `aws configure`). Make sure to select the region you want your vpn to be in.
* An Amazon Linux AMI image with Docker installed (make your own and put the AMI id in the vpn-up.sh script)
* A security group with ports 22 (TCP), 1194 (UDP) and a custom ICMP rule (Echo request) to allow ping requests. You might also like to open the port 443 (TCP) if you want this vpn to work over 443 for obfuscation reasons. Add the security group id in the vpn-up.sh script.
