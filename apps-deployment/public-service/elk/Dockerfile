# Copyright (C) 2001-2018
#
# INFO:
# Touch: It is by Kevin li
# Date:  2018-08-17
# QQ:    2658757934
# blog:  http://home.51cto.com/space?uid=6170059

# Set the base image source.
FROM docker.elastic.co/elasticsearch/elasticsearch:6.4.0

# Set  maintainer information for the images
LABEL maintainer kevin li 2658757934Qqq.com

# Install the elasticserach applications.
COPY run.sh /
RUN chmod 755 /run.sh
# Set the application startup command
CMD ["/run.sh"]
