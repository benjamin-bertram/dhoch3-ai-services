#!/bin/bash

# Quick script to check logs of problematic containers

echo "========================================="
echo "Checking Fooocus logs (unhealthy)..."
echo "========================================="
docker logs --tail 50 dhoch3-fooocus 2>&1
echo ""

echo "========================================="
echo "Checking Forge logs (restarting)..."
echo "========================================="
docker logs --tail 50 dhoch3-forge 2>&1
echo ""

echo "========================================="
echo "Checking FluxGym logs (unhealthy/restarting)..."
echo "========================================="
docker logs --tail 50 dhoch3-fluxgym 2>&1
echo ""

echo "========================================="
echo "Checking AI-Toolkit logs (restarting)..."
echo "========================================="
docker logs --tail 50 dhoch3-ai-toolkit 2>&1
echo ""

echo "========================================="
echo "Checking Traefik status..."
echo "========================================="
docker ps | grep traefik || echo "Traefik not running!"
echo ""

echo "========================================="
echo "Checking if containers are on traefik network..."
echo "========================================="
docker network inspect traefik_default 2>/dev/null | grep -A 5 "Containers" || echo "Traefik network not found!"

