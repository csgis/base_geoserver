#!/bin/sh

# =============================================================================
# GEOSERVER START SCRIPT (Updated for 2.28.x)
# Based on oscarfonts/geoserver with CSGIS customizations
# =============================================================================

# -----------------------------------------------------------------------------
# CORS Configuration (from upstream - enabled by default)
# Set GEOSERVER_CORS_ENABLED=false if Traefik/proxy handles CORS
# -----------------------------------------------------------------------------
if [ "${GEOSERVER_CORS_ENABLED}" != "false" ] && [ -z "$(sed '/<!--/,/-->/d' ${GEOSERVER_INSTALL_DIR}/WEB-INF/web.xml | grep "<filter-name>\s*cross-origin")" ]; then 
  echo "Enabling CORS filter in web.xml..."
  sed -i "\:</web-app>:i\
    <filter>\n\
      <filter-name>cross-origin</filter-name>\n\
      <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
      <init-param>\n\
        <param-name>cors.allowed.origins</param-name>\n\
        <param-value>${GEOSERVER_CORS_ALLOWED_ORIGINS:-*}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
        <param-name>cors.allowed.methods</param-name>\n\
        <param-value>${GEOSERVER_CORS_ALLOWED_METHODS:-GET,POST,PUT,DELETE,HEAD,OPTIONS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
      <param-name>cors.allowed.headers</param-name>\n\
        <param-value>${GEOSERVER_CORS_ALLOWED_HEADERS:-*}</param-value>\n\
      </init-param>\n\
    </filter>\n\
    <filter-mapping>\n\
      <filter-name>cross-origin</filter-name>\n\
      <url-pattern>${GEOSERVER_CORS_URL_PATTERN:-/*}</url-pattern>\n\
    </filter-mapping>" ${GEOSERVER_INSTALL_DIR}/WEB-INF/web.xml
fi

# -----------------------------------------------------------------------------
# Custom UID handling (updated for ubuntu user, was tomcat)
# -----------------------------------------------------------------------------
if [ -n "${CUSTOM_UID}" ]; then
  echo "Using custom UID ${CUSTOM_UID}."
  UBUNTU_UID=$(id -u "ubuntu" 2>/dev/null)
  if [ "$UBUNTU_UID" -eq "$CUSTOM_UID" ]; then
    echo "CUSTOM_UID already in use for ubuntu user. Nothing to do."
  else
    usermod -u ${CUSTOM_UID} ubuntu
    find / -xdev -user 1000 -print0 | xargs -0 -P $(nproc) -n 1 chown -h ubuntu
  fi
fi

# -----------------------------------------------------------------------------
# Custom GID handling (updated for ubuntu user, was tomcat)
# -----------------------------------------------------------------------------
if [ -n "${CUSTOM_GID}" ]; then
  echo "Using custom GID ${CUSTOM_GID}."
  UBUNTU_GID=$(id -g "ubuntu" 2>/dev/null)
  if [ "$UBUNTU_GID" -eq "$CUSTOM_GID" ]; then
    echo "CUSTOM_GID already in use for ubuntu user. Nothing to do."
  else
    groupmod -g ${CUSTOM_GID} ubuntu
    find / -xdev -group 1000 -exec chgrp -h ubuntu '{}' +
  fi
fi

# -----------------------------------------------------------------------------
# Ensure data directory has correct ownership
# Excludes gwc directory to preserve tile cache permissions
# -----------------------------------------------------------------------------
if [ "$(stat -c %U:%G ${GEOSERVER_DATA_DIR})" != "ubuntu:ubuntu" ]; then
  echo "Fixing ownership of ${GEOSERVER_DATA_DIR}..."
  chown -R ubuntu:ubuntu "${GEOSERVER_DATA_DIR}"
fi

# -----------------------------------------------------------------------------
# Install extensions from mounted volume
# Uses find+install instead of for loop (more robust)
# -----------------------------------------------------------------------------
echo "Installing extensions from ${GEOSERVER_EXT_DIR}..."
find "${GEOSERVER_EXT_DIR}" -mindepth 2 -maxdepth 2 -type f -iname '*.jar' \
  -exec install -o ubuntu -g ubuntu -p '{}' /usr/local/geoserver/WEB-INF/lib \;

# -----------------------------------------------------------------------------
# Start Tomcat with dropped privileges
# Uses setpriv instead of su for proper privilege dropping
# -----------------------------------------------------------------------------
# Get all capabilities and prepare to drop them
all_caps=$(setpriv --list-caps | sed -e 's/^/-/' | tr '\n' ',' | sed -e 's/,$//')
command="setpriv --reuid=ubuntu --regid=ubuntu --init-groups --inh-caps=${all_caps}"
command="${command} /usr/local/tomcat/bin/catalina.sh run"

echo "Starting GeoServer as ubuntu user..."
exec ${command}
