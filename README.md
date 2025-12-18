# CSGIS GEOSERVER 2.28

This docker composition is a wrapper around [oscarfonts/geoserver](https://hub.docker.com/r/oscarfonts/geoserver/).

## Features

Compared to the upstream project, this composition adds:

- **HTTPS via Caddy** - Automatic Let's Encrypt certificates with zero configuration
- **Automatic proxyBaseUrl** - Sets the correct proxy URL in GeoServer config
- **Admin password management** - Auto-updates admin password from .env on startup
- **GeoFence + GWC integration** - Pre-configured for GeoWebCache with GeoFence
- **XXE Protection** - WMS/OWS endpoints restricted to GET/HEAD/OPTIONS (CVE-2024-36401)
- **Root path deployment** - GeoServer runs at `/` instead of `/geoserver`
- **Additional fonts** - Noto, DejaVu, Unifont, Hanazono for better labeling
- **Health checks** - Built-in health monitoring for all services

## Upgrade from 2.24.x

If upgrading from GeoServer 2.24.x, note these breaking changes:

| Change | Old (2.24) | New (2.28) |
|--------|------------|------------|
| Container user | `tomcat` (UID 1099) | `ubuntu` (UID 1000) |
| Privilege drop | `su tomcat -c ...` | `setpriv --reuid=ubuntu ...` |
| PostGIS image | `kartoza/postgis:14-3.1` | `kartoza/postgis:16-3.4` |
| CORS | Manual | Auto-configured (disable if Caddy handles it) |
| Reverse proxy | Traefik | Caddy |

**Data migration**: Your GeoServer data directory should migrate forward. Always backup first!

## Quick Start

### 1. Configure environment files
```bash
cp .env.sample .env
cp .db.sample .db
cp .geoserver.sample .geoserver
```

Edit each file with your values:

- `.env` → `SITE_URL` and `ADMIN_EMAIL`
- `.geoserver` → `PROXY_BASE` (must match SITE_URL with `https://`)
- `.db` → Database credentials

### 2. Configure Caddy
```bash
cp caddy/Caddyfile.sample caddy/Caddyfile
```

The default Caddyfile includes XXE protection (blocks POST on `/wms` and `/ows`). If you need to allow POST requests on these endpoints, use the alternative:
```bash
cp caddy/Caddyfile.no-wms_ows_post-blocking caddy/Caddyfile
```

### 3. Download extensions
```bash
chmod +x build_exts_dir.sh
./build_exts_dir.sh -v 2.28.1
```

This creates a `geoserver-exts/` directory with the configured extensions.

### 4. Build and run
```bash
docker-compose build
docker-compose up -d
```

### 5. Access GeoServer

- URL: `https://your-site-url/`
- Default admin: `admin` / (password from .geoserver)

## Extensions

Enabled by default:

- `feature-pregeneralized` - Vector performance optimization
- `pyramid` - Raster pyramid support
- `geofence-server` - Fine-grained access control
- `css` - CSS styling for layers
- `monitor` - Request monitoring
- `control-flow` - Request throttling

Edit the `extensions` file to enable/disable extensions, then re-run `build_exts_dir.sh`.

## Configuration Options

### .env file

| Variable | Description | Default |
|----------|-------------|---------|
| `SITE_URL` | Your domain (without https://) | Required |
| `ADMIN_EMAIL` | Email for Let's Encrypt | Required |

### .geoserver file

| Variable | Description | Default |
|----------|-------------|---------|
| `PROXY_BASE` | Full URL with https:// | Required |
| `GEOSERVER_PATH` | Context path | `/` |
| `GEOSERVER_CORS_ENABLED` | Enable CORS in GeoServer | `false` |
| `GEOSERVER_CSRF_DISABLED` | Disable CSRF protection | `true` |
| `SET_PASSWORD_ON_UP` | Update password on start | `true` |
| `GEOSERVER_ADMIN_PASSWORD` | Admin password | Required |
| `CATALINA_OPTS` | JVM options | See sample |
| `CUSTOM_UID` / `CUSTOM_GID` | Match host user | Optional |

### Security Notes

1. **CORS**: Disabled in GeoServer by default (Caddy handles it). Set `GEOSERVER_CORS_ENABLED=true` if needed.
2. **CSRF**: Disabled for proxy compatibility. Consider a whitelist for production.
3. **XXE Protection**: WMS/OWS POST requests are blocked at Caddy level by default. See `caddy/Caddyfile`.

## Custom Overrides

For client-specific customizations (e.g., external volume mounts), create a custom override file:
```bash
cp docker-compose.custom.yml.sample docker-compose.custom.yml
```

Then enable it in `.env`:
```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.custom.yml
```

This is useful for:

- Mounting GeoServer data from external storage
- Exposing additional ports
- Using a different GeoServer image

## Volumes

| Volume | Purpose |
|--------|---------|
| `geo-db-data` | PostgreSQL/PostGIS data |
| `geoserver_data` | GeoServer data directory |
| `caddy_data` | Caddy certificates and state |
| `caddy_config` | Caddy configuration |
| `./geoserver-exts` | GeoServer extensions |

## Troubleshooting

### Check logs
```bash
docker-compose logs -f geoserver
docker-compose logs -f caddy
```

### Verify extensions loaded

Check GeoServer web UI → About GeoServer → Modules

### Permission issues

Set `CUSTOM_UID` and `CUSTOM_GID` in `.geoserver` to match your host user:
```bash
echo "CUSTOM_UID=$(id -u)" >> .geoserver
echo "CUSTOM_GID=$(id -g)" >> .geoserver
```

### Certificate issues

Caddy stores certificates in the `caddy_data` volume. To force renewal:
```bash
docker-compose down
docker volume rm base_geoserver_caddy_data
docker-compose up -d
```

## License

Based on [oscarfonts/docker-geoserver](https://github.com/oscarfonts/docker-geoserver) (MIT License).
