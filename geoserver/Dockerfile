FROM oscarfonts/geoserver:2.20.1

RUN apt update && apt install vim -y 
COPY ./conf/configure.sh  /usr/local/bin/configure.sh

ENTRYPOINT [ "/bin/sh", "/usr/local/bin/configure.sh"] 
