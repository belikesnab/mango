#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}========================================${NC}"
echo -e "${RED}Stopping Mango Infrastructure${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --remove-volumes    Remove all volumes (WARNING: This deletes all data!)"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  Stop services but keep data"
    echo "  $0 --remove-volumes Stop services and delete all data"
}

# Parse arguments
REMOVE_VOLUMES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Confirmation for volume removal
if [ "$REMOVE_VOLUMES" = true ]; then
    echo -e "${RED}WARNING: This will delete all data in volumes!${NC}"
    echo -e "${YELLOW}The following volumes will be removed:${NC}"
    echo "  - postgres-mango-data"
    echo "  - redis-data"
    echo "  - consul-data"
    echo "  - kafka-data (if exists)"
    echo ""
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}Stopping services...${NC}"

# Stop containers
docker compose down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Services stopped successfully${NC}"
else
    echo -e "${RED}Error stopping services${NC}"
    exit 1
fi

# Remove volumes if requested
if [ "$REMOVE_VOLUMES" = true ]; then
    echo ""
    echo -e "${YELLOW}Removing volumes...${NC}"
    
    docker volume rm postgres-mango-data 2>/dev/null && echo -e "  ${GREEN}✓${NC} postgres-mango-data removed" || echo -e "  ${YELLOW}○${NC} postgres-mango-data not found"
    docker volume rm redis-data 2>/dev/null && echo -e "  ${GREEN}✓${NC} redis-data removed" || echo -e "  ${YELLOW}○${NC} redis-data not found"
    docker volume rm consul-data 2>/dev/null && echo -e "  ${GREEN}✓${NC} consul-data removed" || echo -e "  ${YELLOW}○${NC} consul-data not found"
    docker volume rm kafka-data 2>/dev/null && echo -e "  ${GREEN}✓${NC} kafka-data removed" || echo -e "  ${YELLOW}○${NC} kafka-data not found"
    
    echo ""
    echo -e "${RED}All volumes have been removed!${NC}"
fi

# Show remaining resources
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Current Status${NC}"
echo -e "${BLUE}========================================${NC}"

# Check for any remaining containers
remaining_containers=$(docker ps -a --filter "name=mango-database\|mango-pgbouncer\|kafka\|redis\|consul" --format "{{.Names}}" 2>/dev/null)

if [ -z "$remaining_containers" ]; then
    echo -e "${GREEN}All containers stopped${NC}"
else
    echo -e "${YELLOW}Remaining containers:${NC}"
    echo "$remaining_containers"
fi

# Check for volumes
remaining_volumes=$(docker volume ls --filter "name=postgres-mango-data\|redis-data\|consul-data\|kafka-data" --format "{{.Name}}" 2>/dev/null)

if [ -z "$remaining_volumes" ]; then
    echo -e "${GREEN}No data volumes present${NC}"
else
    echo -e "${YELLOW}Remaining volumes:${NC}"
    echo "$remaining_volumes"
    echo ""
    echo -e "${YELLOW}To remove volumes and all data, run:${NC}"
    echo -e "  ${GREEN}./stop-mango.sh --remove-volumes${NC}"
fi

# Check for network
if docker network inspect mango_mango-network &>/dev/null; then
    echo -e "${YELLOW}Network 'mango-network' still exists (may be in use)${NC}"
else
    echo -e "${GREEN}Network removed${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Infrastructure Stopped${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}To start the infrastructure again:${NC}"
echo -e "  ${GREEN}./start-mango.sh${NC}"
echo ""