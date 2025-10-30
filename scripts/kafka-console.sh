#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kafka Console${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Kafka is running
if ! docker ps | grep -q kafka; then
    echo -e "${RED}Error: Kafka container is not running${NC}"
    echo -e "${YELLOW}Start infrastructure with: ./start-mango.sh${NC}"
    exit 1
fi

show_menu() {
    echo -e "${YELLOW}Available operations:${NC}"
    echo "  1) List topics"
    echo "  2) Create topic"
    echo "  3) Describe topic"
    echo "  4) Delete topic"
    echo "  5) Produce messages (console producer)"
    echo "  6) Consume messages (console consumer)"
    echo "  7) List consumer groups"
    echo "  8) Describe consumer group"
    echo "  9) Show broker information"
    echo "  0) Exit"
    echo ""
}

list_topics() {
    echo -e "${YELLOW}Listing all topics...${NC}"
    docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --list
    echo ""
}

create_topic() {
    read -p "Enter topic name: " topic_name
    read -p "Enter number of partitions (default: 3): " partitions
    partitions=${partitions:-3}
    read -p "Enter replication factor (default: 1): " replication
    replication=${replication:-1}
    
    echo -e "${YELLOW}Creating topic '$topic_name'...${NC}"
    docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --create \
        --topic "$topic_name" \
        --partitions "$partitions" \
        --replication-factor "$replication"
    echo ""
}

describe_topic() {
    read -p "Enter topic name: " topic_name
    echo -e "${YELLOW}Describing topic '$topic_name'...${NC}"
    docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --bootstrap-server localhost:9092 \
        --describe \
        --topic "$topic_name"
    echo ""
}

delete_topic() {
    read -p "Enter topic name: " topic_name
    read -p "Are you sure you want to delete '$topic_name'? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}Deleting topic '$topic_name'...${NC}"
        docker exec kafka /opt/kafka/bin/kafka-topics.sh \
            --bootstrap-server localhost:9092 \
            --delete \
            --topic "$topic_name"
        echo ""
    else
        echo -e "${YELLOW}Deletion cancelled${NC}"
    fi
}

produce_messages() {
    read -p "Enter topic name: " topic_name
    echo -e "${YELLOW}Starting console producer for '$topic_name'${NC}"
    echo -e "${YELLOW}Type messages and press Enter. Press Ctrl+C to exit.${NC}"
    echo ""
    docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh \
        --bootstrap-server localhost:9092 \
        --topic "$topic_name"
    echo ""
}

consume_messages() {
    read -p "Enter topic name: " topic_name
    read -p "Read from beginning? (yes/no, default: no): " from_beginning
    
    echo -e "${YELLOW}Starting console consumer for '$topic_name'${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit.${NC}"
    echo ""
    
    if [ "$from_beginning" = "yes" ]; then
        docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh \
            --bootstrap-server localhost:9092 \
            --topic "$topic_name" \
            --from-beginning
    else
        docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh \
            --bootstrap-server localhost:9092 \
            --topic "$topic_name"
    fi
    echo ""
}

list_consumer_groups() {
    echo -e "${YELLOW}Listing all consumer groups...${NC}"
    docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
        --bootstrap-server localhost:9092 \
        --list
    echo ""
}

describe_consumer_group() {
    read -p "Enter consumer group name: " group_name
    echo -e "${YELLOW}Describing consumer group '$group_name'...${NC}"
    docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
        --bootstrap-server localhost:9092 \
        --describe \
        --group "$group_name"
    echo ""
}

show_broker_info() {
    echo -e "${YELLOW}Broker information:${NC}"
    docker exec kafka /opt/kafka/bin/kafka-broker-api-versions.sh \
        --bootstrap-server localhost:9092
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Select operation (0-9): " choice
    echo ""
    
    case $choice in
        1) list_topics ;;
        2) create_topic ;;
        3) describe_topic ;;
        4) delete_topic ;;
        5) produce_messages ;;
        6) consume_messages ;;
        7) list_consumer_groups ;;
        8) describe_consumer_group ;;
        9) show_broker_info ;;
        0) 
            echo -e "${GREEN}Exiting Kafka console${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            echo ""
            ;;
    esac
done