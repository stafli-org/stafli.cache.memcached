
#
#    CentOS 7 (centos7) Memcached14 Cache System (dockerfile)
#    Copyright (C) 2016-2017 Stafli
#    Luís Pedro Algarvio
#    This file is part of the Stafli Application Stack.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# Build
#

# Base image to use
FROM stafli/stafli.init.supervisor:supervisor31_centos7

# Labels to apply
LABEL description="Stafli Memcached Cache System (stafli/stafli.cache.memcached), Based on Stafli Supervisor Init (stafli/stafli.init.supervisor)" \
      maintainer="lp@algarvio.org" \
      org.label-schema.schema-version="1.0.0-rc.1" \
      org.label-schema.name="Stafli Memcached Cache System (stafli/stafli.cache.memcached)" \
      org.label-schema.description="Based on Stafli Supervisor Init (stafli/stafli.init.supervisor)" \
      org.label-schema.keywords="stafli, memcached, cache, debian, centos" \
      org.label-schema.url="https://stafli.org/" \
      org.label-schema.license="GPLv3" \
      org.label-schema.vendor-name="Stafli" \
      org.label-schema.vendor-email="info@stafli.org" \
      org.label-schema.vendor-website="https://www.stafli.org" \
      org.label-schema.authors.lpalgarvio.name="Luis Pedro Algarvio" \
      org.label-schema.authors.lpalgarvio.email="lp@algarvio.org" \
      org.label-schema.authors.lpalgarvio.homepage="https://lp.algarvio.org" \
      org.label-schema.authors.lpalgarvio.role="Maintainer" \
      org.label-schema.registry-url="https://hub.docker.com/r/stafli/stafli.cache.memcached" \
      org.label-schema.vcs-url="https://github.com/stafli-org/stafli.cache.memcached" \
      org.label-schema.vcs-branch="master" \
      org.label-schema.os-id="centos" \
      org.label-schema.os-version-id="7" \
      org.label-schema.os-architecture="amd64" \
      org.label-schema.version="1.0"

#
# Arguments
#

ARG app_memcached_user="memcached"
ARG app_memcached_group="memcached"
ARG app_memcached_home="/run/memcached"
ARG app_memcached_loglevel="notice"
ARG app_memcached_auth_sasl="no"
ARG app_memcached_listen_proto="auto"
ARG app_memcached_listen_addr="0.0.0.0"
ARG app_memcached_listen_port="11211"
ARG app_memcached_limit_backlog="256"
ARG app_memcached_limit_concurent="256"
ARG app_memcached_limit_memory="128"

#
# Environment
#

# Working directory to use when executing build and run instructions
# Defaults to /.
#WORKDIR /

# User and group to use when executing build and run instructions
# Defaults to root.
#USER root:root

#
# Packages
#

# Refresh the package manager
# Add foreign repositories and GPG keys
#  - remi-release: for Les RPM de remi pour Enterprise Linux 7 (Remi)
# Install the selected packages
#   Install the memcached packages
#    - memcached: for memcached, the Memcached distributed memory object caching system server
# Cleanup the package manager
RUN printf "Installing repositories and packages...\n" && \
    \
    printf "Refresh the package manager...\n" && \
    rpm --rebuilddb && yum makecache && \
    \
    printf "Install the foreign repositories and refresh the GPG keys...\n" && \
    yum install -y \
      http://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum-config-manager --enable remi-safe remi && \
    \
    printf "Install the memcached packages...\n" && \
    yum install -y \
      memcached && \
    \
    printf "Cleanup the package manager...\n" && \
    yum clean all && rm -Rf /var/lib/yum/* && rm -Rf /var/cache/yum/* && \
    \
    printf "Finished installing repositories and packages...\n";

#
# Configuration
#

# Add users and groups
RUN printf "Adding users and groups...\n" && \
    \
    printf "Add memcached user and group...\n" && \
    id -g ${app_memcached_user} \
    || \
    groupadd \
      --system ${app_memcached_group} && \
    id -u ${app_memcached_user} && \
    usermod \
      --gid ${app_memcached_group} \
      --home ${app_memcached_home} \
      --shell /sbin/nologin \
      ${app_memcached_user} \
    || \
    useradd \
      --system --gid ${app_memcached_group} \
      --no-create-home --home-dir ${app_memcached_home} \
      --shell /sbin/nologin \
      ${app_memcached_user} && \
    \
    printf "Finished adding users and groups...\n";

# Supervisor
RUN printf "Updading Supervisor configuration...\n" && \
    \
    # /etc/supervisord.d/init.conf \
    file="/etc/supervisord.d/init.conf" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    perl -0p -i -e "s>supervisorctl start rclocal;>supervisorctl start rclocal; supervisorctl start memcached;>" ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    # /etc/supervisord.d/memcached.conf \
    file="/etc/supervisord.d/memcached.conf" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    printf "# Memcached\n\
[program:memcached]\n\
command=/bin/bash -c \"opts=\$(grep -o '^[^#]*' /etc/memcached.conf) && exec \$(which memcached) \$opts\"\n\
autostart=false\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
stdout_events_enabled=true\n\
stderr_events_enabled=true\n\
\n" > ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    printf "Finished updading Supervisor configuration...\n";

# Memcached
RUN printf "Updading Memcached configuration...\n" && \
    \
    # /etc/sysconfig/memcached \
    file="/etc/sysconfig/memcached" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    # disable daemon/run in foreground \
    perl -0p -i -e "s>OPTIONS=\">OPTIONS=\"#-d >" ${file} && \
    # run as user \
    perl -0p -i -e "s>USER=.*>USER=\"${app_memcached_user}\">" ${file} && \
    # change log level \
    if [ "$app_memcached_loglevel" = "notice" ]; then app_memcached_loglevel_ovr="-v"; elif [ "$app_memcached_loglevel" = "verbose" ]; then app_memcached_loglevel_ovr="-vv"; else app_memcached_loglevel_ovr=""; fi && \
    perl -0p -i -e "s>OPTIONS=\">OPTIONS=\"${app_memcached_loglevel_ovr} >" ${file} && \
    # change interface \
    perl -0p -i -e "s>OPTIONS=\">OPTIONS=\"-l ${app_memcached_listen_addr} >" ${file} && \
    # change port \
    perl -0p -i -e "s>PORT=.*>PORT=\"${app_memcached_listen_port}\">" ${file} && \
    # change backlog queue limit \
    perl -0p -i -e "s>OPTIONS=\">OPTIONS=\"-b ${app_memcached_limit_backlog} >" ${file} && \
    # change max concurrent connections \
    perl -0p -i -e "s>MAXCONN=.*>MAXCONN=\"${app_memcached_limit_concurent}\">" ${file} && \
    # change max memory \
    perl -0p -i -e "s>CACHESIZE=.*>CACHESIZE=\"${app_memcached_limit_memory}\">" ${file} && \
    # change protocol to auto \
    perl -0p -i -e "s>OPTIONS=\">OPTIONS=\"-B ${app_memcached_listen_proto} >" ${file} && \
    # change SASL authentication \
    if [ "$app_memcached_auth_sasl" = "yes" ]; then app_memcached_auth_sasl="-S"; else app_memcached_auth_sasl=""; fi && \
    perl -0p -i -e "s>OPTIONS=\">OPTIONS=\"${app_memcached_auth_sasl} >" ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    # /etc/memcached.conf \
    file="/etc/memcached.conf" && \
    printf "\n# Applying configuration for ${file}...\n" && \
    # clear old file \
    printf "#\n# memcached.conf\n#\n" > ${file} && \
    # disable daemon/run in foreground \
    printf "\n# Run memcached as a daemon.\n#-d\n" >> ${file} && \
    # run as user \
    printf "\n# Specify which user to run memcache on.\n-u ${app_memcached_user}\n" >> ${file} && \
    # change log level \
    if [ "$app_memcached_loglevel" = "notice" ]; then app_memcached_loglevel_ovr="-v"; elif [ "$app_memcached_loglevel" = "verbose" ]; then app_memcached_loglevel_ovr="-vv"; else app_memcached_loglevel_ovr=""; fi && \
    printf "\n# Be verbose\n${app_memcached_loglevel_ovr}\n" >> ${file} && \
    # change log file \
    printf "\n# Log memcached output\n#logfile /proc/self/fd/2\n" >> ${file} && \
    # change interface \
    printf "\n# Specify which IP address to listen on.\n-l ${app_memcached_listen_addr}\n" >> ${file} && \
    # change port \
    printf "\n# Default connection port is 11211\n-p ${app_memcached_listen_port}\n" >> ${file} && \
    # change backlog queue limit \
    printf "\n# Set the backlog queue limit (default: 1024)\n-b ${app_memcached_limit_backlog}\n" >> ${file} && \
    # change max concurrent connections \
    printf "\n# Limit the number of simultaneous incoming connections. The daemon default is 1024\n-c ${app_memcached_limit_concurent}\n" >> ${file} && \
    # change max memory \
    printf "\n# Limit the memory usage.\n-m ${app_memcached_limit_memory}\n" >> ${file} && \
    # change protocol to auto \
    printf "\n# Binding protocol - one of ascii, binary, or auto (default)\n-B ${app_memcached_listen_proto}\n" >> ${file} && \
    # change SASL authentication \
    if [ "$app_memcached_auth_sasl" = "yes" ]; then app_memcached_auth_sasl="-S"; else app_memcached_auth_sasl="#-S"; fi && \
    printf "\n# Turn on SASL authentication\n${app_memcached_auth_sasl}\n" >> ${file} && \
    printf "Done patching ${file}...\n" && \
    \
    printf "\n# Testing configuration...\n" && \
    echo "Testing $(which memcached):"; $(which memcached) -i | grep "memcached" && \
    printf "Done testing configuration...\n" && \
    \
    printf "Finished updading Memcached configuration...\n";

#
# Run
#

# Command to execute
# Defaults to /bin/bash.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "--nodaemon"]

# Ports to expose
# Defaults to 11211
EXPOSE ${app_memcached_listen_port}

