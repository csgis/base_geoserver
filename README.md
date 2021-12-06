# CSGIS GEOSERVER

This docker composition is a wrapper around oscarfonts/geoserver

Compared to the upstream project this composition adds the following:

- enable https via a traefik proxy service
- automaticully sets the correct proxyBaseUrl in geoserver
- allows to auto update the admin password based on .env
- sets a var for gwc working with geofence

## Run it

Set correct values for
- .env -> SITE_URL
- geoserver.env -> PROXY_URL (= SITE_URL with https://)

```
docker-compose build
docker-compose up -d 
```
