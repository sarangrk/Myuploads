# Base shiny image
# FROM  rocker/shiny:latest
FROM nexus.support.data-lab.io:8082/thinkbiganalytics/shiny-base:latest

# Add label metadata
LABEL maintainer="Andre Martin 'andre.martins@thinkbiganalytics.com' & Niket Doshi 'niket.doshi@thinkbiganalytics.com'" \
      version="1.0" \
      description="Dockerized version of the generic-pam app. Shiny server listens at port 3838."

# Copy the app to shiny server pam-demo
COPY pam-analyser/ /srv/shiny-server/pamdemo/

# Modify permission so that shiny server can access it
RUN chmod 555 /srv/shiny-server/pamdemo

EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]
