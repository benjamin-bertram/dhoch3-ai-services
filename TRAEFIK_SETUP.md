# Traefik Integration Setup

## Übersicht

Alle AI-Services sind für die Integration mit dem bestehenden Traefik Reverse Proxy auf dem Server konfiguriert.

## Netzwerk-Konfiguration

### Externes Traefik-Netzwerk

Die Services verwenden das **externe Netzwerk `base`**, das vom Traefik-Container bereitgestellt wird:

```yaml
networks:
  base:
    external: true
    name: base
```

**Wichtig:** Jeder Service, der über Traefik erreichbar sein soll, muss mit dem `base` Netzwerk verbunden sein:

```yaml
services:
  comfyui:
    networks:
      - base
      - ai-services
```

## Traefik Labels

### Basis-Konfiguration

Jeder Service hat folgende Traefik-Labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=base
  - traefik.http.routers.<service>.entrypoints=websecure
  - traefik.http.routers.<service>.rule=Host(`<subdomain>.app.${DOMAIN}`)
  - traefik.http.routers.<service>.tls=true
  - traefik.http.services.<service>.loadbalancer.server.port=<port>
```

### TLS/HTTPS

**Wichtig:** Das Label `traefik.http.routers.<service>.tls=true` aktiviert TLS/HTTPS.

Traefik verwendet automatisch das in der Server-Konfiguration hinterlegte Zertifikat.

**Keine separaten `certresolver` oder `middleware` Labels mehr nötig!**

## Domain-Schema

### Wildcard DNS

Alle Services verwenden das Schema: `<subdomain>.app.design-hoch-drei.de`

**Beispiele:**
- ComfyUI: `comfyui.app.design-hoch-drei.de`
- Forge: `forge.app.design-hoch-drei.de`
- Fooocus: `fooocus.app.design-hoch-drei.de`
- InvokeAI: `invokeai.app.design-hoch-drei.de`
- AI Toolkit: `ai-toolkit.app.design-hoch-drei.de`
- Dockge: `dockge.app.design-hoch-drei.de`

### DNS-Eintrag erforderlich

**Wildcard DNS-Eintrag erstellen:**

```
*.app.design-hoch-drei.de -> <KI-Server IP>
```

**Vorteile:**
- ✅ Nur ein DNS-Eintrag für alle Services
- ✅ Neue Services automatisch erreichbar
- ✅ Keine manuellen DNS-Änderungen mehr nötig

**Kontakt:** Seibold & Partner für DNS-Konfiguration

## Service-Übersicht

| Service | Subdomain | Port | URL |
|---------|-----------|------|-----|
| ComfyUI | comfyui | 8188 | https://comfyui.app.design-hoch-drei.de |
| Fooocus | fooocus | 7860 | https://fooocus.app.design-hoch-drei.de |
| Forge | forge | 7861 | https://forge.app.design-hoch-drei.de |
| InvokeAI | invokeai | 9090 | https://invokeai.app.design-hoch-drei.de |
| AI Toolkit | ai-toolkit | 8675 | https://ai-toolkit.app.design-hoch-drei.de |
| Dockge | dockge | 5001 | https://dockge.app.design-hoch-drei.de |

## Deployment

### 1. DNS konfigurieren

Wildcard DNS-Eintrag erstellen (via Seibold & Partner):

```
*.app.design-hoch-drei.de A <KI-Server IP>
```

### 2. Traefik-Netzwerk prüfen

Sicherstellen, dass das `base` Netzwerk existiert:

```bash
docker network ls | grep base
```

Falls nicht vorhanden, erstellen:

```bash
docker network create base
```

### 3. Services starten

```bash
cd /vol/service/cw/dhoch3-ai-services
docker compose up -d
```

### 4. Traefik-Logs prüfen

```bash
docker logs traefik -f
```

Sollte zeigen:
```
Creating router comfyui@docker
Creating router forge@docker
Creating router fooocus@docker
...
```

### 5. Services testen

```bash
# Test von Server aus
curl -k https://comfyui.app.design-hoch-drei.de
curl -k https://forge.app.design-hoch-drei.de

# Test von extern (nach DNS-Propagierung)
curl https://comfyui.app.design-hoch-drei.de
```

## Troubleshooting

### Service nicht erreichbar

1. **Netzwerk prüfen:**
   ```bash
   docker inspect <container> | grep -A 10 Networks
   ```
   Sollte `base` Netzwerk zeigen.

2. **Traefik-Labels prüfen:**
   ```bash
   docker inspect <container> | grep -A 20 Labels
   ```

3. **Traefik-Dashboard prüfen:**
   - Router sollten sichtbar sein
   - TLS sollte aktiviert sein

### TLS-Fehler

- Sicherstellen, dass `traefik.http.routers.<service>.tls=true` gesetzt ist
- Traefik-Zertifikat-Konfiguration prüfen
- Logs prüfen: `docker logs traefik`

### DNS funktioniert nicht

- DNS-Propagierung kann bis zu 24h dauern
- Lokalen DNS-Cache leeren: `sudo systemd-resolve --flush-caches`
- DNS-Auflösung testen: `nslookup comfyui.app.design-hoch-drei.de`

## Anpassungen

### Subdomain ändern

In `.env` Datei:

```bash
COMFYUI_SUBDOMAIN=my-comfyui
```

Ergibt: `my-comfyui.app.design-hoch-drei.de`

### Domain ändern

In `.env` Datei:

```bash
DOMAIN=andere-domain.de
```

**Wichtig:** DNS-Eintrag muss entsprechend angepasst werden!

---

**Status:** ✅ Konfiguriert und bereit für Deployment

**Nächste Schritte:**
1. Wildcard DNS-Eintrag erstellen lassen
2. Services deployen
3. HTTPS-Zugriff testen

