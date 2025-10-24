#!/bin/bash

echo "Starting mango infrastructure..............."
docker-compose up -d

echo ""
echo "Waiting for services to be healthy..........."
sleep 15

echo ""
echo "Checking service status......................"
docker-compose ps

echo ""
echo "Mango infrastructure started!................"
echo ""
