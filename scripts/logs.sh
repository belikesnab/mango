#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Infrastructure Logs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Service mapping
declare -A services=(
    ["postgres"]="mango-database"
    ["pgbouncer"]="mango-pgbouncer"
    ["kafka"]="kafka"
    ["redis"]="redis"
    ["consul"]="consul"
)

show_menu() {
    echo -e "${YELLOW}Available services:${NC}"
    echo "  1) PostgreSQL (mango-database)"
    echo "  2) PgBouncer (mango-pgbouncer)"
    echo "  3) Kafka"
    echo "  4) Redis"
    echo "  5) Consul"
    echo "  6) All services"
    echo "  0) Exit"
    echo ""
}

show_logs() {
    local service=$1
    local follow=$2
    
    if [ "$follow" = "true" ]; then
        echo -e "${YELLOW}Showing live logs for $service (Press Ctrl+C to exit)...${NC}"
        echo ""
        docker logs -f "$service"
    else
        read -p "Number of lines to show (default: 100): " lines
        lines=${lines:-100}
        echo -e "${YELLOW}Showing last $lines lines for $service...${NC}"
        echo ""
        docker logs --tail "$lines" "$service"
    fi
}

show_all_logs() {
    read -p "Number of lines per service (default: 50): " lines
    lines=${lines:-50}
    
    for service_name in "${!services[@]}"; do
        container="${services[$service_name]}"
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Logs for $container${NC}"
        echo -e "${BLUE}========================================${NC}"
        docker logs --tail "$lines" "$container" 2>&1
        echo ""
    done
}

# Check if a service was specified as argument
if [ $# -eq 1 ]; then
    service_arg=$1
    
    case $service_arg in
        postgres|postgresql|database)
            show_logs "mango-database" "true"
            exit 0
            ;;
        pgbouncer)
            show_logs "mango-pgbouncer" "true"
            exit 0
            ;;
        kafka)
            show_logs "kafka" "true"
            exit 0
            ;;
        redis)
            show_logs "redis" "true"
            exit 0
            ;;
        consul)
            show_logs "consul" "true"
            exit 0
            ;;
        all)
            show_all_logs
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown service: $service_arg${NC}"
            echo -e "${YELLOW}Available services: postgres, pgbouncer, kafka, redis, consul, all${NC}"
            exit 1
            ;;
    esac
fi

# Interactive menu
while true; do
    show_menu
    read -p "Select service (0-6): " choice
    echo ""
    
    case $choice in
        1)
            read -p "Follow logs in real-time? (yes/no, default: no): " follow
            if [ "$follow" = "yes" ]; then
                show_logs "mango-database" "true"
            else
                show_logs "mango-database" "false"
            fi
            echo ""
            ;;
        2)
            read -p "Follow logs in real-time? (yes/no, default: no): " follow
            if [ "$follow" = "yes" ]; then
                show_logs "mango-pgbouncer" "true"
            else
                show_logs "mango-pgbouncer" "false"
            fi
            echo ""
            ;;
        3)
            read -p "Follow logs in real-time? (yes/no, default: no): " follow
            if [ "$follow" = "yes" ]; then
                show_logs "kafka" "true"
            else
                show_logs "kafka" "false"
            fi
            echo ""
            ;;
        4)
            read -p "Follow logs in real-time? (yes/no, default: no): " follow
            if [ "$follow" = "yes" ]; then
                show_logs "redis" "true"
            else
                show_logs "redis" "false"
            fi
            echo ""
            ;;
        5)
            read -p "Follow logs in real-time? (yes/no, default: no): " follow
            if [ "$follow" = "yes" ]; then
                show_logs "consul" "true"
            else
                show_logs "consul" "false"
            fi
            echo ""
            ;;
        6)
            show_all_logs
            echo ""
            ;;
        0)
            echo -e "${GREEN}Exiting logs viewer${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            echo ""
            ;;
    esac
done