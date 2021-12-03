#!/bin/sh

# SETTINGS
USERS_XML=/var/local/geoserver/security/usergroup/default/users.xml 
CLASSPATH=/usr/local/geoserver/WEB-INF/lib/
GLOBAL_XML=/var/local/geoserver/global.xml

echo "----------- GEOSERVER CUSTOM CONFIGURATION START -----------"


# UPGRADE PROXYBASE URL
echo "\nPROXY BASE IS: ${PROXY_BASE}"

grep -q proxyBaseUrl $GLOBAL_XML
if [ $? -eq 0 ]
then
	echo "present"
	echo ${PROXY_BASE}
	sed -i  -e "s#\(<proxyBaseUrl>\).*\(<\/proxyBaseUrl>\)#<proxyBaseUrl>${PROXY_BASE}<\/proxyBaseUrl>#g"
	cat $GLOBAL_XML
else
	echo "not present"
	echo ${PROXY_BASE}
    sed -i "s#<onlineResource>http://geoserver.org</onlineResource>#<onlineResource>http://geoserver.org</onlineResource>\n<proxyBaseUrl>${PROXY_BASE}</proxyBaseUrl>#g" $GLOBAL_XML
	cat $GLOBAL_XML
fi


# UPDATE ADMIN PASSWORD
cp $USERS_XML $USERS_XML.orig
make_hash(){
    NEW_PASSWORD=$1
    (echo "digest1:" && java -classpath $(find $CLASSPATH -regex ".*jasypt-[0-9]\.[0-9]\.[0-9].*jar") org.jasypt.intf.cli.JasyptStringDigestCLI digest.sh algorithm=SHA-256 saltSizeBytes=16 iterations=100000 input="$NEW_PASSWORD" verbose=0) | tr -d '\n'
}


if [ "$SET_PASSWORD_ON_UP" = true ] ; then
   echo "----------- Password update ------------"
   echo "Updating geoserver admin password with: $GEOSERVER_ADMIN_PASSWORD"
   echo "----------- Hash update ------------"
   PWD_HASH=$(make_hash $GEOSERVER_ADMIN_PASSWORD)
   sed -i -e "s| password=\".*\"| password=\"${PWD_HASH}\"|g" $USERS_XML
   echo "----------- Updated File is ------------"
   cat $USERS_XML
   echo "----------- Original File was ------------"
   cat $USERS_XML.orig
fi

echo "\n----------- GEOSERVER CUSTOM CONFIGURATION END -----------"

# run the parent entrypoint
/bin/sh /usr/local/bin/start.sh
