# CSGIS GEOSERVER 2.28

This docker composition is a wrapper around [oscarfonts/geoserver](https://hub.docker.com/r/oscarfonts/geoserver/).

## Features

Compared to the upstream project, this composition adds:

- **HTTPS via Traefik** - Automatic Let's Encrypt certificates
- **Automatic proxyBaseUrl** - Sets the correct proxy URL in GeoServer config
- **Admin password management** - Auto-updates admin password from .env on startup
- **GeoFence + GWC integration** - Pre-configured for GeoWebCache with GeoFence
- **XXE Protection** - WMS endpoint restricted to GET/HEAD/OPTIONS (CVE-2024-36401)
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
| CORS | Manual | Auto-configured (disable if Traefik handles it) |

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

### 2. Download extensions

```bash
chmod +x build_exts_dir.sh
./build_exts_dir.sh -v 2.28.1
```

This creates a `geoserver-exts/` directory with the configured extensions.

### 3. Build and run

```bash
docker-compose build
docker-compose up -d
```

### 4. Access GeoServer

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

1. **CORS**: Disabled in GeoServer by default (Traefik handles it). Set `GEOSERVER_CORS_ENABLED=true` if needed.
2. **CSRF**: Disabled for proxy compatibility. Consider a whitelist for production.
3. **XXE Protection**: WMS POST requests are blocked at Traefik level.

## Volumes

| Volume | Purpose |
|--------|---------|
| `geo-db-data` | PostgreSQL/PostGIS data |
| `geoserver_data` | GeoServer data directory |
| `./letsencrypt` | Let's Encrypt certificates |
| `./geoserver-exts` | GeoServer extensions |

## Troubleshooting

### Check logs
```bash
docker-compose logs -f geoserver
docker-compose logs -f traefik
```

### Verify extensions loaded
Check GeoServer web UI → About GeoServer → Modules

### Permission issues
Set `CUSTOM_UID` and `CUSTOM_GID` in `.geoserver` to match your host user:
```bash
echo "CUSTOM_UID=$(id -u)" >> .geoserver
echo "CUSTOM_GID=$(id -g)" >> .geoserver
```

## License

Based on [oscarfonts/docker-geoserver](https://github.com/oscarfonts/docker-geoserver) (MIT License).
