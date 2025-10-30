#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verifying Mango Infrastructure${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if docker compose is running
if ! docker compose ps &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not running or docker-compose.yml not found${NC}"
    exit 1
fi

# Function to check service health
check_service() {
    local service_name=$1
    local container_name=$2
    
    echo -e "${YELLOW}Checking $service_name...${NC}"
    
    status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
    health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)
    
    if [ -z "$status" ]; then
        echo -e "  Status: ${RED}NOT RUNNING${NC}"
        return 1
    fi
    
    echo -e "  Status: ${GREEN}$status${NC}"
    
    if [ "$health" != "" ] && [ "$health" != "<no value>" ]; then
        if [ "$health" == "healthy" ]; then
            echo -e "  Health: ${GREEN}$health${NC}"
        else
            echo -e "  Health: ${RED}$health${NC}"
        fi
    fi
    
    echo ""
}

# Check all services
all_healthy=true

check_service "PostgreSQL" "mango-database" || all_healthy=false
check_service "PgBouncer" "mango-pgbouncer" || all_healthy=false
check_service "Kafka" "kafka" || all_healthy=false
check_service "Redis" "redis" || all_healthy=false
check_service "Consul" "consul" || all_healthy=false

# Network connectivity tests
echo -e "${YELLOW}Testing service connectivity...${NC}"

# Test PostgreSQL
if docker exec mango-database pg_isready -U postgres &>/dev/null; then
    echo -e "  PostgreSQL: ${GREEN}✓ Accepting connections${NC}"
else
    echo -e "  PostgreSQL: ${RED}✗ Not accepting connections${NC}"
    all_healthy=false
fi

# Test PgBouncer
if docker exec mango-pgbouncer pg_isready -h localhost -p 5432 &>/dev/null; then
    echo -e "  PgBouncer:  ${GREEN}✓ Accepting connections${NC}"
else
    echo -e "  PgBouncer:  ${RED}✗ Not accepting connections${NC}"
    all_healthy=false
fi

# Test Kafka
if docker exec kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092 &>/dev/null; then
    echo -e "  Kafka:      ${GREEN}✓ Broker responding${NC}"
else
    echo -e "  Kafka:      ${RED}✗ Broker not responding${NC}"
    all_healthy=false
fi

# Test Redis
if docker exec redis redis-cli -a "$REDIS_PASS" info server; then
    echo -e "  Redis:      ${GREEN}✓ Responding to ping${NC}"
else
    echo -e "  Redis:      ${RED}✗ Not responding${NC}"
    all_healthy=false
fi

# Test Consul
if docker exec consul consul info &>/dev/null; then
    echo -e "  Consul:     ${GREEN}✓ Agent responding${NC}"
else
    echo -e "  Consul:     ${RED}✗ Agent not responding${NC}"
    all_healthy=false
fi

echo ""

# Volume check
echo -e "${YELLOW}Checking volumes...${NC}"
volumes=("mango_postgres-mango-data" "mango_redis-data" "mango_consul-data")
for vol in "${volumes[@]}"; do
    if docker volume inspect "$vol" &>/dev/null; then
        echo -e "  $vol: ${GREEN}✓ Exists${NC}"
    else
        echo -e "  $vol: ${RED}✗ Missing${NC}"
    fi
done

echo ""

# Network check
echo -e "${YELLOW}Checking network...${NC}"
if docker network inspect mango_mango-network &>/dev/null; then
    echo -e "  mango-network: ${GREEN}✓ Exists${NC}"
else
    echo -e "  mango-network: ${RED}✗ Missing${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"

if [ "$all_healthy" = true ]; then
    echo -e "${GREEN}All services are healthy and operational!${NC}"
    exit 0
else
    echo -e "${RED}Some services are not healthy${NC}"
    echo -e "${YELLOW}Check logs with: ./logs.sh [service-name]${NC}"
    exit 1
fi