FROM oscarfonts/geoserver:2.28.1

# custom configuration
COPY ./conf/configure.sh  /usr/local/bin/configure.sh
COPY ./conf/start.sh /usr/local/bin/start.sh

# run geoserver from root path of domain
COPY conf/ROOT.xml /usr/local/tomcat/conf/Catalina/localhost/ROOT.xml
RUN rm -f /usr/local/tomcat/conf/Catalina/localhost/geoserver.xml

# install extra fonts (on top of Microsoft fonts already in base image)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       fonts-noto \
       fonts-dejavu \
       unifont \
       fonts-hanazono \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/bin/sh", "/usr/local/bin/configure.sh"]
