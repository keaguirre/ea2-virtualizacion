FROM php:8.4.8RC1-apache-bullseye

LABEL maintainer="ke.aguirre@duocuc.cl"

ENV NAGIOS_VERSION=4.5.9 \
    NAGIOS_PLUGINS_VERSION=2.4.9 \
    DEBIAN_FRONTEND=noninteractive

# Instalar dependencias necesarias para compilación y ejecución
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libgd-dev \
    unzip wget curl openssl libssl-dev \
    daemon make libtool libnet-snmp-perl \
    gettext iputils-ping dnsutils sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Crear usuarios y grupos requeridos por Nagios
RUN useradd -m nagios && \
    groupadd nagcmd && \
    usermod -a -G nagcmd nagios && \
    usermod -a -G nagcmd www-data

# Descargar y compilar Nagios Core
RUN cd /tmp && \
    wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz && \
    tar xzf nagios-${NAGIOS_VERSION}.tar.gz && \
    cd nagios-${NAGIOS_VERSION} && \
    ./configure --with-command-group=nagcmd && \
    make all && \
    make install && \
    make install-init && \
    make install-commandmode && \
    make install-config && \
    make install-webconf && \
    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# Descargar y compilar Nagios Plugins
RUN cd /tmp && \
    wget https://nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    tar xzf nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && make install

# Limpiar archivos temporales
RUN rm -rf /tmp/*

# Eliminar herramientas de compilación para reducir el tamaño final
RUN apt-get purge -y \
    build-essential libgd-dev libssl-dev libtool make \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Habilitar módulos de Apache necesarios
RUN a2enmod cgi rewrite

# Copiar script de inicio
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["bash", "/start.sh"]