# Description
Secure Internet Gateway (SIG) using AWS, provides controls for ingress, egress and cross-VPC traffic

## Diagram

![Solution Diagram](ingress-egress-inter-vpc-fw.png)


## Requirements

- The AWS region has needs to support GWLB (e.g. ap-southeast-2). 
- Subscribe to the F5 PAYG-Best 200Mbps image from the AWS marketplace - https://aws.amazon.com/marketplace/pp/B079C3N5PX?qid=1614637412553&sr=0-1&ref_=srh_res_product_title

## Usage example

- Set AWS environment variables
```bash
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

Create the vars file and update it with your settings

```bash
cp admin.auto.tfvars.example admin.auto.tfvars
# MODIFY TO YOUR SETTINGS
```

Run the setup script to deploy all of the components into your AWS account (remember that you are responsible for the cost of those components)

```bash
./setup.sh
```

## BIGIP configuration steps

Connect to the BIGIP using the bigipPublicIp and bigipPassword over port 8443. https://admin:bigipPassword@bigipPublicIp:8443

Upload the 15.1.2 ISO image, upload the EHF iso image, upgrade to the Hotfix-BIGIP-15.1.2.1.0.126.10-ENG EHF and boot the BIGIP.

Change TMM count to 1 (temp step)

```bash
tmsh modify sys db provision.tmmcount value 1
```

Configure a Geneve tunnel - https://techdocs.f5.com/en-us/bigip-14-1-0/big-ip-tmos-tunneling-and-ipsec-14-1-0/creating-ip-tunnels.html

| Object | Value |
|------|---------|
| name | geneve |
| profile | geneve |
| local address | bigip private ip (can be seen at the top left of the UI) |
| everything else  | default value |

Create a 'health check' virtual server to respond

| Object | Value |
|------|---------|
| name | health_check |
| ip address | 0.0.0.0/0 |
| port | 80 |
| VLAN / Tunnel  | internal |
| Protocol  | TCP |
| HTTP profile  | HTTP |
| VLAN / Tunnel  | internal |
| everything else  | default value |


Create a 'fake_self_ip' 10.131.0.1/24, assign it to the tunnel interface

| Object | Value |
|------|---------|
| name | fake_ip_for_tunnel |
| ip address | 10.131.0.1 |
| netmask | 255.255.255.0 |
| VLAN / Tunnel  | geneve |
| everything else  | default value |

Create a static arp entry to 10.131.0.2 ff:ff:ff:ff:ff:ff

| Object | Value |
|------|---------|
| name | fake_arp_entry |
| ip address | 10.131.0.2 |
| MAC address | ff:ff:ff:ff:ff:ff |

Create a node with 10.131.0.2

| Object | Value |
|------|---------|
| name | fake_dg_node |
| ip address | 10.131.0.2 |
| Health Moniors | none |
| everything else  | default value |

Create a pool with the 'fake node'

| Object | Value |
|------|---------|
| name | fake_dg_pool |
| Nodes | fake_dg_node, all services |
| Health Moniors | none |
| everything else  | default value |

Configure a virtual server performance L4, transparent virtual server, assign the pool from previous step.

| Object | Value |
|------|---------|
| name | forwarding_vs |
| Type | performance L4 |
| Destination Address/Mask	 | 0.0.0.0/0 |
| Service Port	  | * All Ports |
| Protocols	  | * All Protocols |
| Vlans and Tunnels	  | geneve |
| Address translation	  | Disabled |
| Source port	  | Preserve strict |
| Default pool	  | fake_dg_pool |

Provision AFM - System --> Resource provisioning --> AFM

Create your AFM policy and logging configuration


## TEST your setup:

SCP your ssh keys to the jumphost (For Testing only, don't use long lived SSH keys)

```bash
scp ~/.ssh/id_rsa ~/.ssh/id_rsa.pub ubuntu@44.230.225.53:~/.ssh/
```

using your ssh key, connect to the Internet Vpc Jumphost - internetVpcData (workspaceManagementAddress)

```bash
ssh ubuntu@x.y.z.p
```

ssh from it to one of the spoke jumphosts (get the private ip from terraform output)

monitor the traffic in AFM

## Cleanup
use the following command to destroy all of the resources

```bash
./destroy.sh
```

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.24 |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| awsAz1 | Availability zone, will dynamically choose one if left empty | `string` | `null` | no |
| awsAz2 | Availability zone, will dynamically choose one if left empty | `string` | `null` | no |
| awsRegion | aws region | `string` | `"us-east-2"` | no |
| projectPrefix | projectPrefix name for tagging | `string` | `"fw-inter-vpc"` | no |
| resourceOwner | Owner of the deployment for tagging purposes | `string` | `"elsa"` | no |
| sshPublicKey | SSH public key used to create an EC2 keypair | `string` | `null` | no |
## Outputs

| Name | Description |
|------|-------------|
| bigipPassword | Password for the admin usernmae |
| bigipPublicIp | Public ip for the BIGIP, access on port 8443 |
| jumphostPublicIp | List of public ip's for the jumphosts |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->



# How to Contribute

Submit a pull request

# Authors
[@shsingh](https://github.com/shsingh)

# Credits
Solution is a heavily modified version of the work done by [yossi-r](https://github.com/yossi-r) and his [solution](https://github.com/f5devcentral/f5-digital-customer-engagement-center/tree/main/solutions/security)
