FROM oscarfonts/geoserver:2.24.4

# custom configuration
COPY ./conf/configure.sh  /usr/local/bin/configure.sh
COPY ./conf/start.sh /usr/local/bin/start.sh

# run geoserver from root path of domain
COPY conf/ROOT.xml /usr/local/tomcat/conf/Catalina/localhost/ROOT.xml
RUN rm /usr/local/tomcat/conf/Catalina/localhost/geoserver.xml

# install extra fonts
RUN apt update
RUN apt install fonts-noto fonts-dejavu unifont fonts-hanazono -y

ENTRYPOINT [ "/bin/sh", "/usr/local/bin/configure.sh"] 
