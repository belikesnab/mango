#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Mango Infrastructure${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo -e "${YELLOW}Please create a .env file with required variables${NC}"
    echo -e "${YELLOW}See .env.example for reference${NC}"
    exit 1
fi

# Load environment variables
source .env

# Validate required environment variables
required_vars=("POSTGRES_USER" "POSTGRES_PASSWORD" "REDIS_PASS" "KAFKA_CLUSTER_ID")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required environment variables:${NC}"
    for var in "${missing_vars[@]}"; do
        echo -e "${RED}  - $var${NC}"
    done
    exit 1
fi

echo -e "${YELLOW}Starting services...${NC}"
docker compose up -d

echo ""
echo -e "${YELLOW}Waiting for services to be healthy...${NC}"

# Wait for all services to be healthy
max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
    healthy_count=$(docker compose ps --format json | jq -r 'select(.Health == "healthy") | .Name' 2>/dev/null | wc -l)
    total_count=$(docker compose ps --format json | jq -r '.Name' 2>/dev/null | wc -l)
    
    if [ "$healthy_count" -eq "$total_count" ] && [ "$total_count" -gt 0 ]; then
        echo -e " ${GREEN}All services are healthy!${NC}"
        break
    fi
    
    echo -ne "\rWaiting... ($((attempt + 1))/$max_attempts) - $healthy_count/$total_count services healthy"
    sleep 2
    ((attempt++))
done

echo ""

if [ $attempt -eq $max_attempts ]; then
    echo -e "${RED}Warning: Not all services became healthy within the timeout period${NC}"
    echo -e "${YELLOW}Run './verify-mango.sh' to check service status${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Infrastructure Started Successfully${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Service URLs:${NC}"
echo -e "  PostgreSQL:   ${GREEN}localhost:5432${NC}"
echo -e "  PgBouncer:    ${GREEN}localhost:6432${NC}"
echo -e "  Kafka:        ${GREEN}localhost:9092${NC}"
echo -e "  Redis:        ${GREEN}localhost:6379${NC}"
echo -e "  Consul UI:    ${GREEN}http://localhost:8500${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  Verify mango: ${GREEN}./verify-mango.sh${NC}"
echo -e "  View logs:             ${GREEN}./logs.sh${NC}"
echo -e "  Database shell:        ${GREEN}./database-shell.sh${NC}"
echo -e "  Kafka console:         ${GREEN}./kafka-console.sh${NC}"
echo -e "  Stop mango:   ${GREEN}./stop-mango.sh${NC}"
echo ""
