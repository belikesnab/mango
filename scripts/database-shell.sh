#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Database Shell${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Check if PostgreSQL is running
if ! docker ps | grep -q mango-database; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    echo -e "${YELLOW}Start infrastructure with: ./start-mango.sh${NC}"
    exit 1
fi

show_menu() {
    echo -e "${YELLOW}Database connection options:${NC}"
    echo "  1) Connect to PostgreSQL (direct - port 5432)"
    echo "  2) Connect to PgBouncer (pooled - port 6432)"
    echo "  3) Execute SQL file"
    echo "  4) Database information"
    echo "  5) List databases"
    echo "  6) List tables in mangodb"
    echo "  7) Create database backup"
    echo "  8) Restore database backup"
    echo "  0) Exit"
    echo ""
}

connect_postgres() {
    echo -e "${YELLOW}Connecting to PostgreSQL directly...${NC}"
    echo -e "${YELLOW}Database: mangodb${NC}"
    echo -e "${YELLOW}User: ${POSTGRES_USER}${NC}"
    echo ""
    docker exec -it mango-database psql -U "${POSTGRES_USER}" -d mangodb
}

connect_pgbouncer() {
    echo -e "${YELLOW}Connecting via PgBouncer...${NC}"
    echo -e "${YELLOW}Database: mangodb${NC}"
    echo -e "${YELLOW}User: ${POSTGRES_USER}${NC}"
    echo ""
    docker exec -it mango-pgbouncer psql -h localhost -p 5432 -U "${POSTGRES_USER}" -d mangodb
}

execute_sql_file() {
    read -p "Enter path to SQL file: " sql_file
    
    if [ ! -f "$sql_file" ]; then
        echo -e "${RED}Error: File not found${NC}"
        return
    fi
    
    echo -e "${YELLOW}Executing SQL file: $sql_file${NC}"
    docker exec -i mango-database psql -U "${POSTGRES_USER}" -d mangodb < "$sql_file"
    echo -e "${GREEN}SQL file executed${NC}"
    echo ""
}

database_info() {
    echo -e "${YELLOW}Database Information:${NC}"
    docker exec mango-database psql -U "${POSTGRES_USER}" -d mangodb -c "
        SELECT 
            version() as postgres_version,
            current_database() as database_name,
            current_user as current_user,
            pg_size_pretty(pg_database_size(current_database())) as database_size;
    "
    echo ""
}

list_databases() {
    echo -e "${YELLOW}Available Databases:${NC}"
    docker exec mango-database psql -U "${POSTGRES_USER}" -d postgres -c "\l"
    echo ""
}

list_tables() {
    echo -e "${YELLOW}Tables in mangodb:${NC}"
    docker exec mango-database psql -U "${POSTGRES_USER}" -d mangodb -c "
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
            pg_stat_get_live_tuples(c.oid) AS row_count
        FROM pg_tables
        JOIN pg_class c ON c.relname = pg_tables.tablename
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    "
    echo ""
}

create_backup() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="backup_mangodb_${timestamp}.sql"
    
    echo -e "${YELLOW}Creating backup...${NC}"
    docker exec mango-database pg_dump -U "${POSTGRES_USER}" -d mangodb > "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup created: $backup_file${NC}"
        backup_size=$(ls -lh "$backup_file" | awk '{print $5}')
        echo -e "${GREEN}Backup size: $backup_size${NC}"
    else
        echo -e "${RED}Backup failed${NC}"
    fi
    echo ""
}

restore_backup() {
    read -p "Enter path to backup file: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: File not found${NC}"
        return
    fi
    
    read -p "This will restore the database. Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}Restoring backup from: $backup_file${NC}"
        docker exec -i mango-database psql -U "${POSTGRES_USER}" -d mangodb < "$backup_file"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Backup restored successfully${NC}"
        else
            echo -e "${RED}Restore failed${NC}"
        fi
    else
        echo -e "${YELLOW}Restore cancelled${NC}"
    fi
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Select option (0-8): " choice
    echo ""
    
    case $choice in
        1) connect_postgres ;;
        2) connect_pgbouncer ;;
        3) execute_sql_file ;;
        4) database_info ;;
        5) list_databases ;;
        6) list_tables ;;
        7) create_backup ;;
        8) restore_backup ;;
        0) 
            echo -e "${GREEN}Exiting database shell${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            echo ""
            ;;
    esac
done