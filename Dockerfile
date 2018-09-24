# base version targeted from Docker Hub
ARG BASE_VERSION=9.5-slim
ARG BASE_NAME=stretch
# Debian base
FROM debian:${BASE_VERSION}
LABEL maintainer="admin@qi2.info"

USER root:root
# app version and debian package version targeted
# from MariaDB repository
ARG APP_VERSION=10.3
ARG APP_RELEASE=10.3.9
ARG APP_PACKAGE=1:10.3.9+maria~stretch
ARG APP_KEY=0xF1656F24C74CD1D8

# Debian setup for MariaDB repository as per : https://downloads.mariadb.org/mariadb/repositories
RUN apt-get update && apt-get install -y --no-install-recommends gnupg dirmngr \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 ${APP_KEY} \
	&& echo "deb [arch=amd64] http://ftp.hosteurope.de/pub/mariadb/repo/${APP_VERSION}/debian ${BASE_NAME} main" > /etc/apt/sources.list.d/mariadb.list \
	&& echo -e "Package: *\nPin: release o=MariaDB'\nPin-Priority: 999" > /etc/apt/preferences.d/mariadb

# setup MariaDB environment
# port (note that config files port definitions make precedence over this, so if different expose manually correct port)
ENV MYSQL_TCP_PORT=3306
# global config file (Alpine MariaDB default) /etc/mysql/my.cnf
# server config file (bind mount file at Docker run for custom config) /etc/mysql/server/my.cnf
# extra config file (bind mount file at Docker run for custom config) /etc/mysql/extra/my.cnf
# databases folder (bind mount folder at Docker run) /var/lib/mysql/
ENV MYSQL_DATABASE=/var/lib/mysql
# server default config, accessed via ENV MYSQL_HOME
ENV MYSQL_HOME=/etc/mysql/server
COPY etc/mysql/server/my.cnf ${MYSQL_HOME}/my.cnf
# extra running config, accessed via --defaults-extra-file
ENV MYSQL_EXTRA=/etc/mysql/extra
COPY etc/mysql/extra/my.cnf ${MYSQL_EXTRA}/my.cnf

# install MariaDB Debian package
# cannot skip initial database creation, use dummy debconf
# initial database creation done in entrypoint if folder missing to ensure bind mounts utlisation
RUN debconf-set-selections="mariadb-server-${APP_VERSION} mysql-server/root_password password dummy" \
	&& debconf-set-selections="mariadb-server-${APP_VERSION} mysql-server/root_password_again password dummy" \
	&& apt-get update && apt-get install -y --no-install-recommends mariadb-server=1:${APP_RELEASE}+maria~${BASE_NAME} \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf ${MYSQL_DATABASE} \
	&& mkdir -p ${MYSQL_DATABASE} \
	&& chown -R mysql:mysql ${MYSQL_DATABASE}
	
# entrypoint bash
COPY usr/local/bin/docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod u+x /usr/local/bin/docker_entrypoint.sh
# setup MariaDB if no mysql database found
# run MariaDB with extra config
EXPOSE ${MYSQL_TCP_PORT}/tcp
ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
