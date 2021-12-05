FROM oscarfonts/geoserver:2.20.1

# custom configuration
COPY ./conf/configure.sh  /usr/local/bin/configure.sh

# run geoserver from root path of domain
COPY conf/ROOT.xml /usr/local/tomcat/conf/Catalina/localhost/ROOT.xml
RUN rm /usr/local/tomcat/conf/Catalina/localhost/geoserver.xml

ENTRYPOINT [ "/bin/sh", "/usr/local/bin/configure.sh"] 
