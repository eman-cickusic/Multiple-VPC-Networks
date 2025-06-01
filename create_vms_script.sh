#!/bin/bash

# create-vms.sh
# Script to create VM instances for the Google Cloud VPC Networks Lab

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
REGION_1="us-central1"
ZONE_1="us-central1-c"
MACHINE_TYPE="e2-micro"
MULTI_NIC_MACHINE_TYPE="e2-standard-4"

echo -e "${BLUE}=== Google Cloud VM Instances Setup ===${NC}"
echo -e "${YELLOW}This script will create VM instances for the lab${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    print_error "No project set. Please run 'gcloud config set project YOUR_PROJECT_ID'"
    exit 1
fi

print_status "Using project: $PROJECT_ID"
print_status "Zone: $ZONE_1"
print_status "Machine type: $MACHINE_TYPE"
echo ""

# Create privatenet-vm-1
print_status "Creating privatenet-vm-1..."
if gcloud compute instances create privatenet-vm-1 \
    --zone=$ZONE_1 \
    --machine-type=$MACHINE_TYPE \
    --subnet=privatesubnet-1 \
    --quiet; then
    print_status "✓ privatenet-vm-1 created successfully"
else
    print_error "Failed to create privatenet-vm-1"
    exit 1
fi

# Note about managementnet-vm-1
print_warning "managementnet-vm-1 should be created via Console as per lab instructions"
print_warning "Please create managementnet-vm-1 manually with the following settings:"
echo "  - Name: managementnet-vm-1"
echo "  - Region: $REGION_1"
echo "  - Zone: $ZONE_1"
echo "  - Machine type: $MACHINE_TYPE"
echo "  - Network: managementnet"
echo "  - Subnetwork: managementsubnet-1"
echo ""

# Note about vm-appliance (multi-NIC VM)
print_warning "vm-appliance (multi-NIC VM) should be created via Console"
print_warning "Please create vm-appliance manually with the following settings:"
echo "  - Name: vm-appliance"
echo "  - Region: $REGION_1"
echo "  - Zone: $ZONE_1"
echo "  - Machine type: $MULTI_NIC_MACHINE_TYPE"
echo "  - Network interfaces:"
echo "    - nic0: privatenet -> privatesubnet-1"
echo "    - nic1: managementnet -> managementsubnet-1"
echo "    - nic2: mynetwork -> mynetwork"
echo ""

# Alternative command for creating vm-appliance (if all networks exist)
echo -e "${BLUE}Alternative: Create vm-appliance via CLI (run after all networks are created):${NC}"
echo "gcloud compute instances create vm-appliance \\"
echo "    --zone=$ZONE_1 \\"
echo "    --machine-type=$MULTI_NIC_MACHINE_TYPE \\"
echo "    --network-interface=subnet=privatesubnet-1,no-address \\"
echo "    --network-interface=subnet=managementsubnet-1,no-address \\"
echo "    --network-interface=subnet=mynetwork,no-address"
echo ""

# Verify VM instances
print_status "Current VM instances:"
echo ""
gcloud compute instances list --sort-by=ZONE --format="table(
    name,
    zone.basename(),
    machineType.machine_type().basename(),
    status,
    networkInterfaces[0].networkIP:label=INTERNAL_IP,
    networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP
)"

echo ""
print_status "VM instances creation completed!"
print_status "Note: Remember to create managementnet-vm-1 and vm-appliance via Console"
print_status "Next step: Test connectivity using test-connectivity.sh"