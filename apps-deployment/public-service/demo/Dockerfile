# Copyright (C) 2001-2018
# 
# INFO:
# Touch: It is by Kevin li
# Date:  2018-08-17
# QQ:    2658757934
# blog:  http://home.51cto.com/space?uid=6170059

# Set the base image source.
FROM registry-mirror.mo9.com/java/alpine:jre1.8

# Set  maintainer information for the images
LABEL maintainer kevin li 2658757934Qqq.com

# Install the java applications. 
EXPOSE 8080
VOLUME /opt/conf
COPY conf/ /opt/conf/
COPY config-service.jar /opt/app.jar

# Set the application startup command
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-Dspring.config.location=/opt/conf/","-jar","/opt/app.jar"]
