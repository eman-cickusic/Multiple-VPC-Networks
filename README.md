# Multiple VPC Networks

A comprehensive guide to creating and managing multiple Virtual Private Cloud (VPC) networks in Google Cloud Platform, including custom networks, firewall rules, VM instances, and multi-network interface configurations.

## Video

https://youtu.be/yXU2B2dhj1Y

## 📋 Overview

This project demonstrates how to work with multiple VPC networks in Google Cloud, providing hands-on experience with:

- Creating custom mode VPC networks with firewall rules
- Deploying VM instances across different networks
- Testing network connectivity between VPC networks
- Configuring VM instances with multiple network interfaces

## 🏗️ Architecture

The lab creates the following network infrastructure:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   mynetwork     │    │  managementnet  │    │   privatenet    │
│   (auto mode)   │    │  (custom mode)  │    │  (custom mode)  │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ mynet-vm-1      │    │ managementnet-  │    │ privatenet-vm-1 │
│ mynet-vm-2      │    │ vm-1            │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ↓
                    ┌─────────────────┐
                    │  vm-appliance   │
                    │ (multi-NIC VM)  │
                    │ Connected to:   │
                    │ • privatenet    │
                    │ • managementnet │
                    │ • mynetwork     │
                    └─────────────────┘
```

## 🚀 Getting Started

### Prerequisites

- Google Cloud Platform account
- Access to Google Cloud Console
- Basic understanding of networking concepts
- gcloud CLI installed (optional, for command-line operations)

### Setup Instructions

1. **Clone this repository**
   ```bash
   git clone <your-repo-url>
   cd vpc-networks-lab
   ```

2. **Set up your Google Cloud environment**
   - Create a new project or use an existing one
   - Enable the Compute Engine API
   - Activate Cloud Shell or configure local gcloud CLI

## 📚 Lab Tasks

### Task 1: Create Custom Mode VPC Networks

#### 1.1 Create the managementnet network (Console)

Navigate to **VPC network > VPC networks** and create:

- **Name**: `managementnet`
- **Subnet creation mode**: Custom
- **Subnet details**:
  - Name: `managementsubnet-1`
  - Region: `<your-region>`
  - IPv4 range: `10.130.0.0/20`

#### 1.2 Create the privatenet network (CLI)

```bash
# Create the privatenet network
gcloud compute networks create privatenet --subnet-mode=custom

# Create privatesubnet-1
gcloud compute networks subnets create privatesubnet-1 \
    --network=privatenet \
    --region=<region-1> \
    --range=172.16.0.0/24

# Create privatesubnet-2
gcloud compute networks subnets create privatesubnet-2 \
    --network=privatenet \
    --region=<region-2> \
    --range=172.20.0.0/20
```

#### 1.3 Verify network creation

```bash
# List all VPC networks
gcloud compute networks list

# List all subnets sorted by network
gcloud compute networks subnets list --sort-by=NETWORK
```

### Task 2: Configure Firewall Rules

#### 2.1 Create firewall rules for managementnet (Console)

- **Name**: `managementnet-allow-icmp-ssh-rdp`
- **Network**: `managementnet`
- **Targets**: All instances in the network
- **Source IPv4 ranges**: `0.0.0.0/0`
- **Protocols and ports**: 
  - TCP: 22, 3389
  - ICMP

#### 2.2 Create firewall rules for privatenet (CLI)

```bash
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=privatenet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0
```

#### 2.3 Verify firewall rules

```bash
# List all firewall rules sorted by network
gcloud compute firewall-rules list --sort-by=NETWORK
```

### Task 3: Create VM Instances

#### 3.1 Create managementnet-vm-1 (Console)

- **Name**: `managementnet-vm-1`
- **Region/Zone**: Select appropriate region/zone
- **Machine type**: `e2-micro`
- **Network**: `managementnet`
- **Subnetwork**: `managementsubnet-1`

#### 3.2 Create privatenet-vm-1 (CLI)

```bash
gcloud compute instances create privatenet-vm-1 \
    --zone=<your-zone> \
    --machine-type=e2-micro \
    --subnet=privatesubnet-1
```

#### 3.3 Verify VM instances

```bash
# List all VM instances sorted by zone
gcloud compute instances list --sort-by=ZONE
```

### Task 4: Test Network Connectivity

#### 4.1 Test external IP connectivity

From `mynet-vm-1`, test connectivity to external IPs:

```bash
# SSH into mynet-vm-1
# Test connectivity to other VMs' external IPs
ping -c 3 <external-ip-of-mynet-vm-2>
ping -c 3 <external-ip-of-managementnet-vm-1>
ping -c 3 <external-ip-of-privatenet-vm-1>
```

**Expected Result**: All pings should succeed ✅

#### 4.2 Test internal IP connectivity

From `mynet-vm-1`, test connectivity to internal IPs:

```bash
# Test connectivity to other VMs' internal IPs
ping -c 3 <internal-ip-of-mynet-vm-2>        # Should work ✅
ping -c 3 <internal-ip-of-managementnet-vm-1> # Should fail ❌
ping -c 3 <internal-ip-of-privatenet-vm-1>    # Should fail ❌
```

**Key Insight**: VMs can only communicate via internal IPs if they're in the same VPC network.

### Task 5: Create Multi-Network Interface VM

#### 5.1 Create vm-appliance with multiple NICs

- **Name**: `vm-appliance`
- **Machine type**: `e2-standard-4`
- **Network interfaces**:
  1. **nic0**: `privatenet` → `privatesubnet-1`
  2. **nic1**: `managementnet` → `managementsubnet-1`
  3. **nic2**: `mynetwork` → `mynetwork`

#### 5.2 Verify network interfaces

```bash
# SSH into vm-appliance
# List network interfaces
sudo ifconfig

# Check routing table
ip route
```

#### 5.3 Test connectivity from multi-NIC VM

```bash
# Test connectivity to VMs in different networks
ping -c 3 <privatenet-vm-1-internal-ip>     # Works ✅
ping -c 3 <managementnet-vm-1-internal-ip>  # Works ✅
ping -c 3 <mynet-vm-1-internal-ip>         # Works ✅
ping -c 3 <mynet-vm-2-internal-ip>         # May not work ❌
```

## 🔧 Scripts and Automation

All commands used in this lab are available in the `/scripts` directory:

- `create-networks.sh` - Automated network creation
- `create-firewall-rules.sh` - Firewall rule setup
- `create-vms.sh` - VM instance creation
- `test-connectivity.sh` - Connectivity testing scripts

## 📊 Network Configuration Summary

| Network | Type | Subnets | CIDR Range | Firewall Rules |
|---------|------|---------|------------|----------------|
| default | Auto | Auto-created | 10.128.0.0/20+ | Default rules |
| mynetwork | Auto | Auto-created | 10.128.0.0/20+ | Custom rules |
| managementnet | Custom | managementsubnet-1 | 10.130.0.0/20 | SSH, RDP, ICMP |
| privatenet | Custom | privatesubnet-1, privatesubnet-2 | 172.16.0.0/24, 172.20.0.0/20 | SSH, RDP, ICMP |

## 🧪 Key Learning Points

1. **VPC Network Isolation**: VPC networks are isolated by default - VMs in different networks cannot communicate via internal IPs without additional configuration (VPC peering, VPN, etc.)

2. **Auto vs Custom Mode**: 
   - Auto mode networks automatically create subnets in all regions
   - Custom mode networks require manual subnet creation, providing more control

3. **Multi-NIC VMs**: 
   - VMs can have multiple network interfaces (up to 8, depending on machine type)
   - Each interface gets its own internal IP and can connect to different VPC networks
   - Default route typically goes through the primary interface (nic0)

4. **Firewall Rules**: 
   - Control traffic at the network level
   - Can be applied to all instances or specific targets
   - Support multiple protocols and port ranges

## 🔍 Troubleshooting

### Common Issues

1. **VM cannot ping internal IPs in other networks**
   - Verify VMs are in the same VPC network
   - Check firewall rules allow ICMP traffic

2. **Multi-NIC VM routing issues**
   - Check routing table with `ip route`
   - Remember default route uses primary interface

3. **SSH connection failures**
   - Verify firewall rules allow TCP port 22
   - Check VM has external IP if connecting from internet

## 📈 Next Steps

After completing this lab, consider exploring:

- VPC Peering for cross-network communication
- Cloud VPN for secure connections
- Cloud Interconnect for hybrid connectivity
- Network Load Balancing across multiple VPCs
- Cloud NAT for private instance internet access

## 🤝 Contributing

Feel free to contribute improvements to this lab guide:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

If you encounter issues or have questions:

- Check the troubleshooting section above
- Review Google Cloud documentation
- Open an issue in this repository

---
