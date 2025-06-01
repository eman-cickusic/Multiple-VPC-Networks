#!/bin/bash

# create-networks.sh
# Script to create VPC networks for the Google Cloud VPC Networks Lab

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
REGION_1="us-central1"
REGION_2="us-east1"

echo -e "${BLUE}=== Google Cloud VPC Networks Setup ===${NC}"
echo -e "${YELLOW}This script will create the VPC networks for the lab${NC}"
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

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "Not authenticated with gcloud. Please run 'gcloud auth login'"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    print_error "No project set. Please run 'gcloud config set project YOUR_PROJECT_ID'"
    exit 1
fi

print_status "Using project: $PROJECT_ID"
print_status "Region 1: $REGION_1"
print_status "Region 2: $REGION_2"
echo ""

# Create privatenet network
print_status "Creating privatenet VPC network..."
if gcloud compute networks create privatenet --subnet-mode=custom --quiet; then
    print_status "✓ privatenet network created successfully"
else
    print_error "Failed to create privatenet network"
    exit 1
fi

# Create privatesubnet-1
print_status "Creating privatesubnet-1 in $REGION_1..."
if gcloud compute networks subnets create privatesubnet-1 \
    --network=privatenet \
    --region=$REGION_1 \
    --range=172.16.0.0/24 \
    --quiet; then
    print_status "✓ privatesubnet-1 created successfully"
else
    print_error "Failed to create privatesubnet-1"
    exit 1
fi

# Create privatesubnet-2
print_status "Creating privatesubnet-2 in $REGION_2..."
if gcloud compute networks subnets create privatesubnet-2 \
    --network=privatenet \
    --region=$REGION_2 \
    --range=172.20.0.0/20 \
    --quiet; then
    print_status "✓ privatesubnet-2 created successfully"
else
    print_error "Failed to create privatesubnet-2"
    exit 1
fi

# Note about managementnet
print_warning "managementnet should be created via the Console as per lab instructions"
print_warning "Please create managementnet manually with the following settings:"
echo "  - Name: managementnet"
echo "  - Subnet creation mode: Custom"
echo "  - Subnet name: managementsubnet-1"
echo "  - Region: $REGION_1"
echo "  - IPv4 range: 10.130.0.0/20"
echo ""

# Verify networks were created
print_status "Verifying network creation..."
echo ""
echo -e "${BLUE}Current VPC networks:${NC}"
gcloud compute networks list --format="table(name,subnet_mode,bgp_routing_mode)"

echo ""
echo -e "${BLUE}Current subnets:${NC}"
gcloud compute networks subnets list --sort-by=NETWORK --format="table(name,region,network,range)"

echo ""
print_status "Network creation completed!"
print_status "Next step: Create firewall rules using create-firewall-rules.sh"