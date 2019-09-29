# docker build -t kevinwangcy/reposync:latest .
# 
#       docker run -d --name repo-sync-<repo-org-name> -v "$PWD/repos/<repo-org-name>:/repo" kevinwangcy/reposync:latest \
#               -e UPSTREAM_USERNAME='$UPSTREAM_USERNAME' \
#               -e UPSTREAM_PASSWORD='$UPSTREAM_PASSWORD' \
#               -e UPSTREAM_ORGNAME='FOGDB'    \
#               -e DOWNSTREAM_USERNAME='$DOWNSTREAM_USERNAME' \
#               -e DOWNSTREAM_PASSWORD='$DOWNSTREAM_PASSWORD'
# 
# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM kevinwangcy/basebuildbox:latest

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# ...put your own build instructions here...
RUN mkdir -p /etc/my_init.d
COPY sync-repo-scheduler.sh /etc/my_init.d/sync-repo-scheduler.sh
RUN chmod +x /etc/my_init.d/sync-repo-scheduler.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


