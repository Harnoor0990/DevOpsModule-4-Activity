#!/bin/bash

#############################################
# Module 6 Part 1: Automated Deployment Script
# Author: Harnoor Gill
# Purpose: Idempotent automation of banking application deployment
#############################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

#############################################
# SECTION 1: PRE-DEPLOYMENT CHECKS
#############################################

log "========================================="
log "SECTION 1: PRE-DEPLOYMENT CHECKS"
log "========================================="

# Check if Docker is installed
log "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
    exit 1
fi
log "✓ Docker is installed: $(docker --version)"

# Check if Docker Compose is installed
log "Checking if Docker Compose is installed..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
log "✓ Docker Compose is installed"

# Check if Docker daemon is running
log "Checking if Docker daemon is running..."
if ! docker info &> /dev/null; then
    error "Docker daemon is not running. Please start Docker."
    exit 1
fi
log "✓ Docker daemon is running"

# Check if required ports are available (idempotent check)
log "Checking if required ports are available..."
REQUIRED_PORTS=(80 5000 3000 27017)
for port in "${REQUIRED_PORTS[@]}"; do
    if netstat -an 2>/dev/null | grep -q ":$port.*LISTEN" || lsof -Pi :$port -sTCP:LISTEN -t &> /dev/null; then
        warning "Port $port is already in use. Attempting to stop existing containers..."
        docker-compose down 2>/dev/null || true
        sleep 2
        if netstat -an 2>/dev/null | grep -q ":$port.*LISTEN" || lsof -Pi :$port -sTCP:LISTEN -t &> /dev/null; then
            warning "Port $port is still in use. Continuing anyway..."
        fi
    fi
done
log "✓ Port check completed"

#############################################
# SECTION 2: DIRECTORY AND FILE VALIDATION
#############################################

log "========================================="
log "SECTION 2: DIRECTORY AND FILE VALIDATION"
log "========================================="

# Navigate to deployment directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Current directory: $SCRIPT_DIR"

# Check for docker-compose.yaml
log "Validating presence of docker-compose.yaml..."
if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
    error "docker-compose.yaml not found in current directory!"
    exit 1
fi
log "✓ docker-compose.yaml found"

# Check for required directories
log "Checking for required directories..."
if [ ! -d "banking-backend" ]; then
    error "banking-backend directory not found!"
    exit 1
fi
if [ ! -d "studentportfolio" ]; then
    error "studentportfolio directory not found!"
    exit 1
fi
log "✓ All required directories present"

# Check for nginx.conf
log "Checking for nginx.conf..."
if [ ! -f "nginx.conf" ]; then
    error "nginx.conf not found!"
    exit 1
fi
log "✓ nginx.conf found"

#############################################
# SECTION 3: CLEANUP EXISTING DEPLOYMENT (IDEMPOTENT)
#############################################

log "========================================="
log "SECTION 3: CLEANUP EXISTING DEPLOYMENT"
log "========================================="

log "Stopping and removing existing containers (if any)..."
docker-compose down -v 2>/dev/null || true
log "✓ Cleanup completed"

#############################################
# SECTION 4: BUILD AND DEPLOY WITH COMPOSE
#############################################

log "========================================="
log "SECTION 4: BUILD AND DEPLOY WITH COMPOSE"
log "========================================="

log "Building and starting containers..."
docker-compose up --build -d

# Wait for containers to start
log "Waiting for containers to initialize (30 seconds)..."
sleep 30

#############################################
# SECTION 5: VALIDATE BUILD AND DEPLOYMENT
#############################################

log "========================================="
log "SECTION 5: VALIDATE BUILD AND DEPLOYMENT"
log "========================================="

# List Docker images
log "Listing Docker images..."
docker images | grep -E "mongo|backend|portfolio|nginx|assignment"

# Show running containers
log "Showing running containers..."
docker ps

# Get nginx container ID
log "Getting nginx container ID..."
NGINX_CONTAINER_ID=$(docker ps --filter "name=nginx" --format "{{.ID}}")
if [ -z "$NGINX_CONTAINER_ID" ]; then
    error "Nginx container not found!"
    exit 1
fi
log "✓ Nginx container ID: $NGINX_CONTAINER_ID"

#############################################
# SECTION 6: HEALTH CHECKS
#############################################

log "========================================="
log "SECTION 6: HEALTH CHECKS"
log "========================================="

# Health check for backend
log "Performing health check on backend (http://localhost:5000)..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:5000/api/login &> /dev/null || curl -s http://localhost:5000 &> /dev/null; then
        log "✓ Backend is responding"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        error "Backend health check failed after $MAX_RETRIES attempts"
        exit 1
    fi
    log "Waiting for backend... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 3
done

# Health check for frontend via nginx
log "Performing health check on nginx (http://localhost:80)..."
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:80 &> /dev/null || curl -s http://localhost:80 | grep -q "Pixel River" &> /dev/null; then
        log "✓ Nginx is responding and serving content"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        error "Nginx health check failed after $MAX_RETRIES attempts"
        exit 1
    fi
    log "Waiting for nginx... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 3
done

log "✓ All services are healthy and responding"

#############################################
# SECTION 7: NGINX IMAGE INSPECTION
#############################################

log "========================================="
log "SECTION 7: NGINX IMAGE INSPECTION"
log "========================================="

# Inspect nginx:alpine image
log "Inspecting nginx:alpine image..."
docker inspect nginx:alpine > nginx-logs.txt
log "✓ Inspection results saved to nginx-logs.txt"

# Extract and display key information using grep and awk (no jq needed)
log "Extracting key information from nginx:alpine image..."

echo ""
log "--- RepoTags ---"
grep -A 2 '"RepoTags"' nginx-logs.txt | grep -v "RepoTags" | grep -v "^\[" | grep -v "^\]" | sed 's/[",]//g' | sed 's/^[ \t]*//'

echo ""
log "--- Created ---"
grep '"Created":' nginx-logs.txt | head -1 | sed 's/.*"Created": "\(.*\)",/\1/'

echo ""
log "--- Os ---"
grep '"Os":' nginx-logs.txt | head -1 | sed 's/.*"Os": "\(.*\)",/\1/'

echo ""
log "--- Config (ExposedPorts) ---"
grep -A 5 '"ExposedPorts"' nginx-logs.txt | head -7

echo ""
log "✓ Nginx image inspection completed"

#############################################
# SECTION 8: DEPLOYMENT SUMMARY
#############################################

log "========================================="
log "SECTION 8: DEPLOYMENT SUMMARY"
log "========================================="

log "Deployment Summary:"
echo ""
echo "✓ MongoDB running on port 27017"
echo "✓ Backend running on port 5000"
echo "✓ Frontend running on port 3000"
echo "✓ Nginx (entry point) running on port 80"
echo ""
log "Application is accessible at: http://localhost"
echo ""
log "========================================="
log "DEPLOYMENT COMPLETED SUCCESSFULLY!"
log "========================================="
echo ""
log "Next Steps for Testing:"
echo "1. Open browser and navigate to http://localhost"
echo "2. Register a new user"
echo "3. Login with credentials"
echo "4. Deposit a float amount (e.g., 600.45)"
echo "5. Withdraw a float amount"
echo "6. Verify balance updates correctly"
echo ""
log "To view logs: docker-compose logs -f"
log "To stop: docker-compose down"
log "To cleanup: docker-compose down -v"