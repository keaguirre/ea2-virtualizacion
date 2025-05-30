#!/bin/bash

# Asegurar que www-data esté en el grupo correcto
usermod -a -G nagcmd www-data

# Reparar permisos del estado
chgrp -R nagcmd /usr/local/nagios/var
chmod -R g+rw /usr/local/nagios/var

# Crear la estructura necesaria si no existe (requerido por Nagios)
mkdir -p /usr/local/nagios/var/spool/checkresults
mkdir -p /usr/local/nagios/var/rw
chown -R nagios:nagios /usr/local/nagios/var
chmod -R 775 /usr/local/nagios/var
chown -R nagios:nagcmd /usr/local/nagios/var


# Habilitar módulos necesarios por si falta algo
a2enmod cgi rewrite

# Reiniciar Apache (en caso de primer arranque)
service apache2 restart

# Validar configuración de Nagios
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Iniciar Nagios como proceso principal
exec /usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
