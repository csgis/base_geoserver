#!/bin/sh

# PATH DEFINITIONS ------------------------------------------
GLOBAL_XML=/var/local/geoserver/global.xml
USERS_XML=/var/local/geoserver/security/usergroup/default/users.xml 
CLASSPATH=/usr/local/geoserver/WEB-INF/lib/
GS_DIR=/var/local/geoserver/geofence/
GS_PROPERTIES=/var/local/geoserver/geofence/geofence-server.properties
GEOFENCE_EXTENSION_DIR=/var/local/geoserver-exts/geofence

# FUNCTIONS --------------------------------------------------
_headline() { 
      printf %0$((40))d\\n | tr 0 \# ;
      echo "$1"
      printf %0$((40))d\\n | tr 0 \# ;
  }

make_hash(){
    NEW_PASSWORD=$1
    (echo "digest1:" && java -classpath $(find $CLASSPATH -regex ".*jasypt-[0-9]\.[0-9]\.[0-9].*jar") org.jasypt.intf.cli.JasyptStringDigestCLI digest.sh algorithm=SHA-256 saltSizeBytes=16 iterations=100000 input="$NEW_PASSWORD" verbose=0) | tr -d '\n'
}


_headline "GEOSERVER CUSTOM CONFIGURATION START"

# UPGRADE PROXYBASE URL --------------------------------------
grep -q proxyBaseUrl $GLOBAL_XML
if [ $? -eq 0 ]
then
	echo "proxy base definition is present!"
	echo ${PROXY_BASE}
	sed -i  -e "s#\(<proxyBaseUrl>\).*\(<\/proxyBaseUrl>\)#<proxyBaseUrl>${PROXY_BASE}<\/proxyBaseUrl>#g"
	cat $GLOBAL_XML
else
	echo "proxy base definition is not present!"
	echo ${PROXY_BASE}
        sed -i "s#<onlineResource>http://geoserver.org</onlineResource>#<onlineResource>http://geoserver.org</onlineResource>\n<proxyBaseUrl>${PROXY_BASE}</proxyBaseUrl>#g" $GLOBAL_XML
	cat $GLOBAL_XML
fi


# UPDATE ADMIN PASSWORD ---------------------------------------
cp $USERS_XML "$USERS_XML.orig"

if [ "$SET_PASSWORD_ON_UP" = true ] ; then
   _headline "password configuration"
   PWD_HASH=$(make_hash $GEOSERVER_ADMIN_PASSWORD)

   echo "Updating geoserver admin password with: $GEOSERVER_ADMIN_PASSWORD\n"
   echo "hash is: $PWD_HASH \n"
   sed -i -e "s| password=\".*\"| password=\"${PWD_HASH}\"|g" $USERS_XML
   cat $USERS_XML
fi


# ENABLE GWC WITH GF -------------------------------------------
if [ -d "$GEOFENCE_EXTENSION_DIR" ]; then
   _headline "update gefence regarding geowebcache\n"
   mkdir -p $GS_DIR
   touch $GS_PROPERTIES
   if ! grep -q "gwc.context.suffix=gwc" $GS_PROPERTIES; then
       echo "suffix not present ... adding it\n"
       echo gwc.context.suffix=gwc >> $GS_PROPERTIES
   fi
fi


# run the parent entrypoint ------------------------------------
_headline "GEOSERVER CUSTOM CONFIGURATION END"
/bin/sh /usr/local/bin/start.sh

