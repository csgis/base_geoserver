# SCRIPT TO CUSTOMIZE THE PARENT GEOSERVER -------------------

echo "\n----------- GEOSERVER CUSTOM CONFIGURATION START  -----------\n"
echo "GEOSERVER CUSTOM CONFIGURATION"
echo "PROXY BASE IS: ${PROXY_BASE}"



# UPGRADE PROXYBASE URL --------------------------------------
GLOBAL_XML=/var/local/geoserver/global.xml

grep -q proxyBaseUrl $GLOBAL_XML
if [ $? -eq 0 ]
then
	echo "\n----------- proxy base definition is present -----------\n"
	echo ${PROXY_BASE}
	sed -i  -e "s#\(<proxyBaseUrl>\).*\(<\/proxyBaseUrl>\)#<proxyBaseUrl>${PROXY_BASE}<\/proxyBaseUrl>#g"
	cat $GLOBAL_XML
else
	echo "\n----------- proxy base definition is not present -----------\n"
	echo ${PROXY_BASE}
        sed -i "s#<onlineResource>http://geoserver.org</onlineResource>#<onlineResource>http://geoserver.org</onlineResource>\n<proxyBaseUrl>${PROXY_BASE}</proxyBaseUrl>#g" $GLOBAL_XML
	cat $GLOBAL_XML
fi

# UPDATE ADMIN PASSWORD ---------------------------------------
USERS_XML=/var/local/geoserver/security/usergroup/default/users.xml 
CLASSPATH=/usr/local/geoserver/WEB-INF/lib/

cp $USERS_XML "$USERS_XML.orig"

make_hash(){
    NEW_PASSWORD=$1
    (echo "digest1:" && java -classpath $(find $CLASSPATH -regex ".*jasypt-[0-9]\.[0-9]\.[0-9].*jar") org.jasypt.intf.cli.JasyptStringDigestCLI digest.sh algorithm=SHA-256 saltSizeBytes=16 iterations=100000 input="$NEW_PASSWORD" verbose=0) | tr -d '\n'
}

if [ "$SET_PASSWORD_ON_UP" = true ] ; then
   echo "\n----------- password configuration ------------\n"
   echo "Updating geoserver admin password with: $GEOSERVER_ADMIN_PASSWORD"
   echo "\n----------- hash is ------------\n"
   PWD_HASH=$(make_hash $GEOSERVER_ADMIN_PASSWORD)
   echo $PWD_HASH
   sed -i -e "s| password=\".*\"| password=\"${PWD_HASH}\"|g" $USERS_XML
   cat $USERS_XML
fi


# ENABLE GWC WITH GF -------------------------------------------
GS_DIR=/var/local/geoserver/geofence/
GS_PROPERTIES=/var/local/geoserver/geofence/geofence-server.properties

echo "\n----------- update gf -----------\n"
mkdir -p $GS_DIR
touch $GS_PROPERTIES
if ! grep -q "gwc.context.suffix=gwc" $GS_PROPERTIES; then
    echo "suffix not present ... adding it"
    echo gwc.context.suffix=gwc >> $GS_PROPERTIES
fi

echo "\n----------- GEOSERVER CUSTOM CONFIGURATION END -----------\n"


# run the parent entrypoint ------------------------------------
/bin/sh /usr/local/bin/start.sh

