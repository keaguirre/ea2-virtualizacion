FROM ubuntu:25.10

LABEL maintainer="ke.aguirre@duocuc.cl"

ENV NAGIOS_VERSION=4.5.9
ENV NAGIOS_PLUGINS_VERSION=2.4.9
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias
RUN apt-get update && \
    apt-get install -y \
    apache2 \
    php \
    libapache2-mod-php \
    build-essential \
    libgd-dev \
    unzip \
    wget \
    curl \
    openssl \
    libssl-dev \
    libmcrypt-dev \
    daemon \
    make \
    libtool \
    libnet-snmp-perl \
    gettext \
    iputils-ping \
    dnsutils \
    sudo

# Crear usuario y grupos
RUN useradd nagios && \
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
    htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# Descargar y compilar Nagios Plugins
RUN cd /tmp && \
    wget https://nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    tar xzf nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz && \
    cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && \
    make install

# Habilitar módulos necesarios de Apache
RUN a2enmod cgi rewrite

# Limpieza
RUN rm -rf /tmp/*

# Copiar script de inicio
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["bash", "/start.sh"]