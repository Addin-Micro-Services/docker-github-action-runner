#!/bin/bash

# manage-runners.sh - Simple script to manage organization-level GitHub Actions runners

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Load environment variables from .env file
load_env() {
    if [ -f ".env" ]; then
        print_info "Loading configuration from .env file..."
        export $(grep -v '^#' .env | xargs)
    else
        print_warning ".env file not found. Please create one or set environment variables manually."
    fi
}

# Validate required environment variables
validate_env() {
    if [ -z "$GITHUB_ORG_TOKEN" ]; then
        print_error "GITHUB_ORG_TOKEN not set!"
        print_info "Please set it in .env file or export GITHUB_ORG_TOKEN='your-token'"
        print_info "Get your token from: $GITHUB_URL/settings/actions/runners"
        exit 1
    fi
    
    if [ -z "$GITHUB_URL" ]; then
        print_error "GITHUB_URL not set!"
        print_info "Please set it in .env file"
        exit 1
    fi
    
    # Set defaults
    RUNNER_LABELS=${RUNNER_LABELS:-"docker,self-hosted,linux,org"}
    MEMORY_LIMIT=${MEMORY_LIMIT:-"2G"}
    CPU_LIMIT=${CPU_LIMIT:-"2.0"}
    
    print_info "Configuration loaded:"
    print_info "  GitHub URL: $GITHUB_URL"
    print_info "  Labels: $RUNNER_LABELS"
    print_info "  Memory Limit: $MEMORY_LIMIT"
    print_info "  CPU Limit: $CPU_LIMIT"
    print_info "  Token: ${GITHUB_ORG_TOKEN:0:10}..."
}

# Get Docker group ID for proper permissions
setup_docker_permissions() {
    if command -v docker &> /dev/null; then
        DOCKER_GID=$(getent group docker | cut -d: -f3 2>/dev/null || echo "999")
        export DOCKER_GID
        print_info "Docker group ID: $DOCKER_GID"
    else
        print_warning "Docker not found, using default GID 999"
        export DOCKER_GID=999
    fi
}

# Create work directories
create_work_dirs() {
    print_info "Creating work directories..."
    mkdir -p runner-work-1 runner-work-2 runner-work-3 runner-work-4
    chmod 755 runner-work-*
}

# Start runners with docker-compose
up() {
    local services="$1"
    load_env
    validate_env
    setup_docker_permissions
    create_work_dirs
    
    if [ -z "$services" ]; then
        print_header "Starting Default Runners (1 & 2)"
        docker-compose up -d github-runner-1 github-runner-2
        print_info "2 runners started."
    else
        print_header "Starting Specified Services"
        docker-compose up -d $services
        print_info "Specified runners started."
    fi
}

# Start with profiles
up_with_profile() {
    local profile="$1"
    load_env
    validate_env
    setup_docker_permissions
    create_work_dirs
    
    print_header "Starting with Profile: $profile"
    docker-compose --profile $profile up -d
    print_info "Runners started with profile: $profile"
}

# Monitor runners
monitor() {
    print_header "Runner Status"
    
    echo "Active Containers:"
    docker-compose ps
    
    echo -e "\nResource Usage:"
    if docker-compose ps -q | grep -q .; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" $(docker-compose ps -q)
    else
        print_warning "No runners currently running"
    fi
    
    echo -e "\nRecent Logs:"
    for service in github-runner-1 github-runner-2 github-runner-3 github-runner-4; do
        if docker-compose ps "$service" 2>/dev/null | grep -q "Up"; then
            echo -e "\n${BLUE}=== $service ===${NC}"
            docker-compose logs --tail=3 "$service"
        fi
    done
}

# Stop runners
down() {
    print_header "Stopping All Runners"
    docker-compose --profile extra down
    print_info "All runners stopped"
}

# Restart specific runner
restart() {
    local runner_num=$1
    if [ -z "$runner_num" ] || ! [[ "$runner_num" =~ ^[1-4]$ ]]; then
        print_error "Please specify runner number: 1, 2, 3, or 4"
        exit 1
    fi
    
    local service_name="github-runner-$runner_num"
    print_header "Restarting $service_name"
    
    docker-compose restart "$service_name"
    print_info "Runner $runner_num restarted"
}

# Show logs
logs() {
    local runner_num=$1
    if [ -z "$runner_num" ]; then
        print_info "Showing logs for all runners..."
        docker-compose logs -f
    elif [[ "$runner_num" =~ ^[1-4]$ ]]; then
        print_info "Showing logs for runner $runner_num..."
        docker-compose logs -f "github-runner-$runner_num"
    else
        print_error "Please specify runner number: 1, 2, 3, or 4 (or leave empty for all)"
        exit 1
    fi
}

# Build/rebuild containers
build() {
    print_header "Building Runner Images"
    docker-compose build --no-cache
    print_info "Runner images built successfully"
}

# Clean up everything
cleanup() {
    print_header "Cleaning Up"
    docker-compose --profile extra down -v
    docker image prune -f
    print_info "Cleanup completed"
}

# Create sample .env file
create_env() {
    if [ -f ".env" ]; then
        print_warning ".env file already exists. Backing up to .env.backup"
        cp .env .env.backup
    fi
    
    cat > .env << 'EOF'
# GitHub Organization Runner Configuration
# Get your token from: https://github.com/your-org-name/settings/actions/runners

# Required: GitHub organization runner token
GITHUB_ORG_TOKEN=your-token-here

# Required: GitHub organization URL
GITHUB_URL=https://github.com/your-org-name

# Optional: Runner labels (comma-separated)
RUNNER_LABELS=docker,self-hosted,linux,org

# Optional: Resource limits
MEMORY_LIMIT=2G
CPU_LIMIT=2.0

# Optional: Docker group ID (auto-detected if not set)
# DOCKER_GID=999
EOF
    
    print_info ".env file created. Please edit it with your GitHub token:"
    print_info "  nano .env"
    print_info ""
    print_info "Get your token from:"
    print_info "  https://github.com/your-org-name/settings/actions/runners"
}

# Show usage
usage() {
    echo "GitHub Actions Organization Runner Manager"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  up [services]           - Start default runners (1,2) or specified services"
    echo "  up-extra                - Start all runners including extras (1,2,3,4)"
    echo "  monitor                 - Show runner status and resource usage"
    echo "  down                    - Stop all runners"
    echo "  restart <1-4>           - Restart specific runner"
    echo "  logs [1-4]              - Show logs (all or specific runner)"
    echo "  build                   - Build/rebuild runner images"
    echo "  cleanup                 - Stop and clean up everything"
    echo "  create-env              - Create sample .env file"
    echo ""
    echo "Configuration (.env file):"
    echo "  GITHUB_ORG_TOKEN        - GitHub organization runner token (required)"
    echo "  GITHUB_URL              - GitHub organization URL (required)"
    echo "  RUNNER_LABELS           - Runner labels (default: docker,self-hosted,linux,org)"
    echo "  MEMORY_LIMIT            - Memory limit per runner (default: 2G)"
    echo "  CPU_LIMIT               - CPU limit per runner (default: 2.0)"
    echo ""
    echo "Examples:"
    echo "  $0 create-env                          # Create .env template"
    echo "  $0 up                                  # Start runners 1 & 2"
    echo "  $0 up github-runner-1                 # Start only runner 1"
    echo "  $0 up github-runner-1 github-runner-3 # Start runners 1 & 3"
    echo "  $0 up-extra                            # Start all 4 runners"
    echo "  $0 monitor                             # Check status"
    echo "  $0 logs 1                              # View runner 1 logs"
    echo "  $0 restart 2                           # Restart runner 2"
    echo ""
    echo "Docker Compose Examples:"
    echo "  docker-compose up -d github-runner-1 github-runner-2    # Start specific runners"
    echo "  docker-compose --profile extra up -d                   # Start all runners"
    echo "  docker-compose ps                                       # Check status"
    echo "  docker-compose down                                     # Stop runners"
    echo ""
    echo "Setup:"
    echo "  1. Run: $0 create-env"
    echo "  2. Edit .env with your GitHub token and preferences"
    echo "  3. Run: $0 up"
}

# Main script logic
case "$1" in
    up)
        shift
        up "$*"
        ;;
    up-extra)
        up_with_profile "extra"
        ;;
    monitor)
        monitor
        ;;
    down)
        down
        ;;
    restart)
        restart "$2"
        ;;
    logs)
        logs "$2"
        ;;
    build)
        build
        ;;
    cleanup)
        cleanup
        ;;
    create-env)
        create_env
        ;;
    *)
        usage
        exit 1
        ;;
esac