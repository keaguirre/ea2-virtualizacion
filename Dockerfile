FROM ubuntu:22.04

LABEL maintainer="ke.aguirre@duocuc.cl"

ENV NAGIOS_VERSION=4.5.9 \
    NAGIOS_PLUGINS_VERSION=2.4.9 \
    DEBIAN_FRONTEND=noninteractive

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    apache2 php libapache2-mod-php \
    build-essential libgd-dev \
    unzip wget curl openssl libssl-dev \
    daemon make libtool libnet-snmp-perl \
    gettext iputils-ping dnsutils sudo \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario y grupos
RUN useradd -m nagios && \
    groupadd nagcmd && \
    usermod -a -G nagcmd nagios && \
    usermod -a -G nagcmd www-data

# Descargar y compilar Nagios Core + Plugins
RUN cd /tmp && \
    wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar xzf nagios-${NAGIOS_VERSION}.tar.gz && \
    cd nagios-${NAGIOS_VERSION} && \
    ./configure --with-command-group=nagcmd && \
    make all && make install && \
    make install-init && make install-commandmode && \
    make install-config && make install-webconf && \
    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin && \
    cd /tmp && \
    wget https://nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    tar xzf nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && make install && \
    rm -rf /tmp/*

# Habilitar módulos necesarios de Apache
RUN a2enmod cgi rewrite

# Copiar script de inicio
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["bash", "/start.sh"]