#!/bin/bash

# create-firewall-rules.sh
# Script to create firewall rules for the Google Cloud VPC Networks Lab

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Google Cloud Firewall Rules Setup ===${NC}"
echo -e "${YELLOW}This script will create firewall rules for VPC networks${NC}"
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
echo ""

# Create firewall rule for privatenet
print_status "Creating firewall rule for privatenet..."
if gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=privatenet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0 \
    --quiet; then
    print_status "✓ privatenet firewall rule created successfully"
else
    print_error "Failed to create privatenet firewall rule"
    exit 1
fi

# Note about managementnet firewall rules
print_warning "managementnet firewall rule should be created via Console as per lab instructions"
print_warning "Please create managementnet firewall rule manually with the following settings:"
echo "  - Name: managementnet-allow-icmp-ssh-rdp"
echo "  - Network: managementnet"
echo "  - Targets: All instances in the network"
echo "  - Source filter: IPv4 Ranges"
echo "  - Source IPv4 ranges: 0.0.0.0/0"
echo "  - Protocols and ports:"
echo "    - TCP: 22, 3389"
echo "    - ICMP: checked"
echo ""

# Verify firewall rules
print_status "Current firewall rules:"
echo ""
gcloud compute firewall-rules list --sort-by=NETWORK --format="table(
    name,
    network,
    direction,
    priority,
    sourceRanges.list():label=SRC_RANGES,
    allowed[].map().firewall_rule().list():label=ALLOW,
    targetTags.list():label=TARGET_TAGS
)"

echo ""
print_status "Firewall rules creation completed!"
print_status "Note: Remember to create the managementnet firewall rule via Console"
print_status "Next step: Create VM instances using create-vms.sh"