#!/bin/sh

# =============================================================================
# GEOSERVER CUSTOM CONFIGURATION SCRIPT (Updated for 2.28.x)
# 
# This script runs BEFORE start.sh and handles:
# 1. SET OR UPDATE proxyBaseUrl
# 2. UPDATE THE ADMIN PASSWORD (username remains: admin)
# 3. SET NEEDED VARIABLE FOR GWC WORKING WITH GEOFENCE
#
# author: toni.schoenbuchner@csgis.de
# updated: 2024 for GeoServer 2.28.x compatibility
# =============================================================================

# PATH DEFINITIONS ------------------------------------------

CLASSPATH=${GEOSERVER_INSTALL_DIR}/WEB-INF/lib/
GEOFENCE_EXTENSION_DIR=${GEOSERVER_EXT_DIR}/geofence-server
GS_DIR=${GEOSERVER_DATA_DIR}/geofence/

GLOBAL_XML=${GEOSERVER_DATA_DIR}/global.xml
USERS_XML=${GEOSERVER_DATA_DIR}/security/usergroup/default/users.xml
GS_PROPERTIES=${GEOSERVER_DATA_DIR}/geofence/geofence-server.properties


# FUNCTIONS --------------------------------------------------

_headline() {
    printf %0$((40))d\\n | tr 0 \# ;
    echo "$1"
    printf %0$((40))d\\n | tr 0 \# ;
}

# Taken from https://github.com/kartoza/docker-geoserver/ who took it from geosolutions ;)
make_hash(){
    NEW_PASSWORD=$1
    (echo "digest1:" && java -classpath $(find $CLASSPATH -regex ".*jasypt-[0-9]\.[0-9]\.[0-9].*jar") org.jasypt.intf.cli.JasyptStringDigestCLI digest.sh algorithm=SHA-256 saltSizeBytes=16 iterations=100000 input="$NEW_PASSWORD" verbose=0) | tr -d '\n'
}

_headline "GEOSERVER CUSTOM CONFIGURATION START"


# 1. UPGRADE PROXYBASE URL --------------------------------------

if [ -f "$GLOBAL_XML" ]; then
    grep -q proxyBaseUrl $GLOBAL_XML
    if [ $? -eq 0 ]; then
        echo "proxy base definition is present! Will Update proxyBaseUrl"
        sed -i -e "s|\(<proxyBaseUrl>\).*\(</proxyBaseUrl>\)|<proxyBaseUrl>${PROXY_BASE}</proxyBaseUrl>|" $GLOBAL_XML
    else
        echo "proxy base definition is not present! Will add proxyBaseUrl"
        sed -i -e "s|<onlineResource>http://geoserver.org</onlineResource>|& \n<proxyBaseUrl>${PROXY_BASE}</proxyBaseUrl>|" $GLOBAL_XML
    fi
    
    echo "Proxy base is: ${PROXY_BASE}"
    echo "global.xml contents:"
    cat $GLOBAL_XML
else
    echo "WARNING: global.xml not found at ${GLOBAL_XML}"
    echo "This is normal on first start - GeoServer will create it."
fi


# 2. UPDATE ADMIN PASSWORD ---------------------------------------

if [ "$SET_PASSWORD_ON_UP" = true ] && [ -f "$USERS_XML" ]; then
    cp $USERS_XML "$USERS_XML.orig"
    
    _headline "password configuration"
    PWD_HASH=$(make_hash $GEOSERVER_ADMIN_PASSWORD)
    
    echo "Updating geoserver admin password with: $GEOSERVER_ADMIN_PASSWORD"
    echo "hash is: $PWD_HASH"
    sed -i -e "s| password=\".*\"| password=\"${PWD_HASH}\"|g" $USERS_XML
    cat $USERS_XML
elif [ "$SET_PASSWORD_ON_UP" = true ]; then
    echo "WARNING: users.xml not found at ${USERS_XML}"
    echo "Password will not be updated on first start."
fi


# 3. ENABLE GWC WITH GF -------------------------------------------

if [ -d "$GEOFENCE_EXTENSION_DIR" ]; then
    _headline "update geofence regarding geowebcache"
    mkdir -p $GS_DIR
    touch $GS_PROPERTIES
    if ! grep -q "gwc.context.suffix=gwc" $GS_PROPERTIES; then
        echo "suffix not present ... adding it"
        echo "gwc.context.suffix=gwc" >> $GS_PROPERTIES
    fi
fi


# run the start script ------------------------------------

_headline "GEOSERVER CUSTOM CONFIGURATION END"
/bin/sh /usr/local/bin/start.sh
