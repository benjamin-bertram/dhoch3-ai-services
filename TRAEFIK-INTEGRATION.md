# Traefik Integration Guide

## Overview

This project is configured to work with Traefik reverse proxy for production deployment. All services are accessible via HTTPS with automatic SSL/TLS certificates from Let's Encrypt.

---

## Configuration Pattern

Based on the server's existing Traefik setup (`docker-compose-dhoch3.yml`), all services now include:

### 1. **HTTPS/TLS Configuration**
```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=${TRAEFIK_NETWORK:-base}
  - traefik.http.routers.SERVICE.entrypoints=websecure
  - traefik.http.routers.SERVICE.tls=true
  - traefik.http.routers.SERVICE.tls.certresolver=${CERT_RESOLVER:-letsencryptresolver}
```

### 2. **Routing Rules**
```yaml
  - traefik.http.routers.SERVICE.rule=Host(`${SUBDOMAIN}.${DOMAIN}`)
```

### 3. **Middleware (Authentication & Security)**
```yaml
  - traefik.http.routers.SERVICE.middlewares=${TRAEFIK_MIDDLEWARE:-default@file}
```

### 4. **Load Balancer**
```yaml
  - traefik.http.services.SERVICE.loadbalancer.server.port=PORT
```

---

## Environment Variables

### Required in `.env`

```bash
# Domain Configuration
DOMAIN=design-hoch-drei.de

# Traefik Network (must match your Traefik network name)
TRAEFIK_NETWORK=base

# Certificate Resolver (from Traefik static config)
CERT_RESOLVER=letsencryptresolver

# Middleware (from Traefik dynamic config)
TRAEFIK_MIDDLEWARE=default@file
```

### Service Subdomains

```bash
COMFYUI_SUBDOMAIN=comfyui
FOOOCUS_SUBDOMAIN=fooocus
FORGE_SUBDOMAIN=forge
INVOKEAI_SUBDOMAIN=invokeai
FLUXGYM_SUBDOMAIN=fluxgym
AI_TOOLKIT_SUBDOMAIN=ai-toolkit
DOCKGE_SUBDOMAIN=dockge
```

---

## Service URLs (Production)

With `DOMAIN=design-hoch-drei.de`:

| Service | URL | Port |
|---------|-----|------|
| ComfyUI | https://comfyui.design-hoch-drei.de | 8188 |
| Fooocus | https://fooocus.design-hoch-drei.de | 7860 |
| Forge | https://forge.design-hoch-drei.de | 7861 |
| InvokeAI | https://invokeai.design-hoch-drei.de | 9090 |
| FluxGym | https://fluxgym.design-hoch-drei.de | 3000 |
| AI Toolkit | https://ai-toolkit.design-hoch-drei.de | 8080 |
| Dockge | https://dockge.design-hoch-drei.de | 5001 |

---

## Middleware Configuration

### Default Middleware (`default@file`)
Applied to all AI services. Typically includes:
- Rate limiting
- Security headers
- CORS configuration
- Compression

### Admin Middleware (`admin-auth@file`)
Applied to Dockge (management interface). Includes:
- HTTP Basic Authentication
- IP whitelisting (optional)
- Additional security headers

**Example Dockge configuration:**
```yaml
- traefik.http.routers.dockge.middlewares=admin-auth@file,default@file
- traefik.http.routers.dockge.priority=1000
```

---

## Network Configuration

### Production Setup

Services connect to two networks:
1. **`traefik`** - External network for Traefik communication
2. **`ai-services`** - Internal network for inter-service communication

```yaml
networks:
  ai-services:
    driver: bridge
  traefik:
    external: true
    name: ${TRAEFIK_NETWORK:-base}
```

### Local Testing

For local testing without Traefik, services use direct port mapping:
```bash
# Access services directly
http://localhost:7860  # Fooocus
http://localhost:7861  # Forge
http://localhost:8188  # ComfyUI
```

---

## Deployment Steps

### 1. Verify Traefik Network

```bash
# Check if Traefik network exists
docker network ls | grep base

# If not, create it
docker network create base
```

### 2. Update Environment Variables

Edit `.env` file:
```bash
DOMAIN=design-hoch-drei.de
TRAEFIK_NETWORK=base
CERT_RESOLVER=letsencryptresolver
TRAEFIK_MIDDLEWARE=default@file
```

### 3. Deploy Services

```bash
# Deploy all services
docker compose up -d

# Or deploy specific service
docker compose up -d forge
```

### 4. Verify Traefik Routes

```bash
# Check Traefik dashboard
# Look for routers: comfyui, fooocus, forge, etc.

# Test SSL certificate
curl -I https://forge.design-hoch-drei.de
```

---

## Troubleshooting

### Service not accessible via domain

**Check:**
1. Traefik network connection:
   ```bash
   docker inspect dhoch3-forge | grep -A 10 Networks
   ```

2. Traefik labels:
   ```bash
   docker inspect dhoch3-forge | grep -A 20 Labels
   ```

3. DNS resolution:
   ```bash
   nslookup forge.design-hoch-drei.de
   ```

### SSL Certificate issues

**Check:**
1. Certificate resolver name matches Traefik config
2. Domain is publicly accessible
3. Ports 80 and 443 are open

### 404 Not Found

**Check:**
1. Service is running: `docker ps | grep forge`
2. Service port is correct in labels
3. Router rule matches your domain

---

## Security Considerations

### 1. Authentication
- Dockge uses `admin-auth@file` middleware
- Consider adding authentication to AI services if exposed publicly

### 2. Rate Limiting
- Configure in Traefik middleware
- Prevents abuse of AI services

### 3. IP Whitelisting
- Restrict access to specific IPs if needed
- Configure in Traefik middleware

### 4. HTTPS Only
- All services use `websecure` entrypoint
- HTTP redirects to HTTPS (configure in Traefik)

---

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Labels](https://doc.traefik.io/traefik/routing/providers/docker/)
- [Let's Encrypt](https://letsencrypt.org/)
- Server config: `docker-compose-dhoch3.yml`

