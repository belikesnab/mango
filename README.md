# Mango Infrastructure

A comprehensive Docker-based infrastructure stack, featuring PostgreSQL with connection pooling, Kafka message broker, Redis cache, and Consul service discovery.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Services](#services)
- [Management Scripts](#management-scripts)
- [Configuration](#configuration)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## 🏗️ Architecture Overview

The infrastructure consists of five main services:

```
┌─────────────────────────────────────────────────────────┐
│                    mango-network                        │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐   ┌───────────┐   │
│  │  PostgreSQL  │◄───│  PgBouncer   │   │   Kafka   │   │
│  │   (5432)     │    │    (6432)    │   │   (9092)  │   │
│  └──────────────┘    └──────────────┘   └───────────┘   │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐                   │
│  │    Redis     │    │    Consul    │                   │
│  │   (6379)     │    │    (8500)    │                   │
│  └──────────────┘    └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

### Services Description

- **PostgreSQL**: Primary relational database (port 5432)
- **PgBouncer**: Connection pooling for PostgreSQL (port 6432)
- **Kafka**: Message broker using KRaft mode (ports 9092, 9093)
- **Redis**: In-memory cache with persistence (port 6379)
- **Consul**: Service discovery and configuration (port 8500)

## 📦 Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- bash shell (for management scripts)
- `jq` command-line tool (for JSON parsing in scripts)

### Platform Support

The infrastructure is configured for **Apple Silicon (ARM64)** by default. For other architectures:

1. Edit `docker-compose.yml`
2. Change `platform: linux/arm64` to `platform: linux/amd64` in the PostgreSQL service

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Create environment file from template
cp .env.example .env

# Edit .env with your credentials
nano .env
```

### 2. Generate Kafka Cluster ID

```bash
# On macOS/Linux
uuidgen

# On Windows PowerShell
[guid]::NewGuid().ToString()

# Add the generated ID to your .env file as KAFKA_CLUSTER_ID
```

### 3. Make Scripts Executable

```bash
chmod +x *.sh
```

### 4. Start Infrastructure

```bash
./start-mango.sh
```

### 5. Verify Everything is Running

```bash
./verify-mango.sh
```

## 🛠️ Services

### PostgreSQL Database

- **Container**: `mango-database`
- **Port**: 5432
- **Database**: `mangodb`
- **Volume**: `postgres-mango-data`

**Health Check**: Verifies database accepts connections every 10 seconds

### PgBouncer Connection Pool

- **Container**: `mango-pgbouncer`
- **Port**: 6432
- **Pool Mode**: Transaction
- **Max Connections**: 100 clients, 50 database connections
- **Pool Size**: 20 (default), 5 (minimum), 5 (reserve)

**Recommended Use**: Connect applications through PgBouncer (port 6432) for better connection management.

### Kafka Message Broker

- **Container**: `kafka`
- **Ports**: 9092 (client), 9093 (controller)
- **Mode**: KRaft (no ZooKeeper required)
- **Default Partitions**: 3
- **Auto-create Topics**: Enabled

**Storage**: Uses tmpfs for development (data not persisted on restart)

### Redis Cache

- **Container**: `redis`
- **Port**: 6379
- **Persistence**: AOF (Append-Only File) enabled
- **Volume**: `redis-data`
- **Auth**: Password protected (from .env)

### Consul Service Discovery

- **Container**: `consul`
- **Ports**: 8500 (HTTP/UI), 8600 (DNS)
- **Mode**: Single-node server
- **UI**: Available at http://localhost:8500
- **Volume**: `consul-data`

## 📜 Management Scripts

### start-mango.sh

Starts all services and waits for health checks.

```bash
./start-mango.sh
```

**Features**:
- Validates environment variables
- Starts all containers
- Waits for services to become healthy (up to 60 attempts)
- Displays service URLs

### verify-mango.sh

Checks the health and connectivity of all services.

```bash
./verify-mango.sh
```

**Checks**:
- Container status and health
- Service connectivity
- Volume existence
- Network configuration

### kafka-console.sh

Interactive console for Kafka operations.

```bash
./kafka-console.sh
```

**Operations**:
1. List topics
2. Create topic
3. Describe topic
4. Delete topic
5. Produce messages (console producer)
6. Consume messages (console consumer)
7. List consumer groups
8. Describe consumer group
9. Show broker information

### database-shell.sh

Interactive shell for PostgreSQL operations.

```bash
./database-shell.sh
```

**Operations**:
1. Connect to PostgreSQL (direct)
2. Connect to PgBouncer (pooled)
3. Execute SQL file
4. Show database information
5. List databases
6. List tables with sizes
7. Create database backup
8. Restore database backup

**Backup Example**:
```bash
# Creates backup_mangodb_YYYYMMDD_HHMMSS.sql
./database-shell.sh
# Select option 7
```

### logs.sh

View service logs interactively or via command line.

```bash
# Interactive mode
./logs.sh

# Direct service logs (follows in real-time)
./logs.sh postgres
./logs.sh kafka
./logs.sh redis
./logs.sh consul
./logs.sh all
```

**Features**:
- Follow logs in real-time
- View historical logs (configurable line count)
- View all services at once

### stop-mango.sh

Stops all services with optional data removal.

```bash
# Stop services, keep data
./stop-mango.sh

# Stop services and remove all data
./stop-mango.sh --remove-volumes
```

**Options**:
- `--remove-volumes`: Deletes all volumes (requires typing 'DELETE' to confirm)
- `--help`: Show usage information

## ⚙️ Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# PostgreSQL
POSTGRES_USER=mango_user
POSTGRES_PASSWORD=strong_password_here

# Redis
REDIS_PASS=redis_password_here

# Kafka
KAFKA_CLUSTER_ID=your-unique-cluster-id
```

### Connection Strings

**PostgreSQL (Direct)**:
```
postgresql://mango_user:password@localhost:5432/mangodb
```

**PostgreSQL (via PgBouncer - Recommended)**:
```
postgresql://mango_user:password@localhost:6432/mangodb
```

**Redis**:
```
redis://:redis_password@localhost:6379
```

**Kafka**:
```
kafka:9092  # From inside Docker network
localhost:9092  # From host machine
```

**Consul**:
```
http://localhost:8500  # HTTP API and UI
```

## 🔧 Common Operations

### Working with Kafka

**Create a Topic**:
```bash
./kafka-console.sh
# Select option 2, enter topic name and configuration
```

**Produce Test Messages**:
```bash
./kafka-console.sh
# Select option 5, enter topic name, then type messages
```

**Consume Messages**:
```bash
./kafka-console.sh
# Select option 6, enter topic name
```

### Database Operations

**Connect to Database**:
```bash
./database-shell.sh
# Select option 1 for direct or 2 for pooled connection
```

**Run SQL Script**:
```bash
./database-shell.sh
# Select option 3, provide file path
```

**Backup Database**:
```bash
./database-shell.sh
# Select option 7
# Backup saved as: backup_mangodb_YYYYMMDD_HHMMSS.sql
```

### Viewing Logs

**Real-time Logs**:
```bash
./logs.sh postgres
# Or use the interactive menu
```

**Last 100 Lines**:
```bash
./logs.sh
# Select service, choose 'no' for follow, enter line count
```

### Service Health Check

```bash
# Quick verification
./verify-mango.sh

# Check specific service logs
docker logs mango-database
docker logs kafka
```

## 🐛 Troubleshooting

### Services Won't Start

1. Check environment variables:
```bash
cat .env
```

2. Verify Docker is running:
```bash
docker ps
```

3. Check for port conflicts:
```bash
lsof -i :5432  # PostgreSQL
lsof -i :6432  # PgBouncer
lsof -i :9092  # Kafka
lsof -i :6379  # Redis
lsof -i :8500  # Consul
```

### Service Unhealthy

Check service logs:
```bash
./logs.sh [service-name]
```

Common issues:
- **PostgreSQL**: Check POSTGRES_USER and POSTGRES_PASSWORD
- **PgBouncer**: Ensure PostgreSQL is healthy first
- **Kafka**: Verify KAFKA_CLUSTER_ID is set
- **Redis**: Check REDIS_PASS is correct

### Kafka Connection Issues

Ensure Kafka is fully started (can take 30+ seconds):
```bash
docker logs kafka | grep "Started"
```

### Database Connection Refused

1. Verify PostgreSQL is healthy:
```bash
docker exec mango-database pg_isready -U postgres
```

2. Check PgBouncer logs:
```bash
./logs.sh pgbouncer
```

### Reset Everything

Complete reset (deletes all data):
```bash
./stop-mango.sh --remove-volumes
./start-mango.sh
```

## 🔒 Security Considerations

### Production Deployment

**DO NOT use this configuration as-is in production.** Consider:

1. **Passwords**: Use strong, randomly generated passwords
2. **Secrets Management**: Use Docker secrets or external secret managers
3. **Network Isolation**: Restrict external access to services (maybe Traefik)
4. **TLS/SSL**: Enable encryption for all services
5. **Authentication**: Configure proper authentication for Kafka and Consul
6. **Backups**: Implement automated backup strategies
7. **Monitoring**: Add health monitoring and alerting
8. **Resource Limits**: Configure memory and CPU limits for containers

### Environment File Security

```bash
# Ensure .env is not committed to version control
echo ".env" >> .gitignore

# Set appropriate permissions
chmod 600 .env
```

### Network Security

For production, consider:
- Using Docker networks with custom DNS
- Implementing network policies
- Using service mesh for inter-service communication
- Enabling TLS for all connections

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PgBouncer Documentation](https://www.pgbouncer.org/usage.html)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Redis Documentation](https://redis.io/documentation)
- [Consul Documentation](https://www.consul.io/docs)

## 📝 License

This infrastructure configuration is provided as-is.

## 🤝 Contributing

When contributing to this infrastructure:

1. Test all changes thoroughly in development
2. Update documentation for any configuration changes
3. Ensure scripts remain cross-platform compatible
4. Add health checks for new services
5. Update the troubleshooting section for known issues

---

**Questions or Issues?** Check the logs first with `./logs.sh`, then verify the infrastructure with `./verify-mango.sh`.