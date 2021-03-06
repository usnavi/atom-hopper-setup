#!/bin/bash

# this script will download and install the most recent version of atomhopper 
#   with the specified configuration

function log {
  echo '[' `date` '] ' $1 >> install-ah.log
  echo '[' `date` '] ' $1
}

SRC=war
CONF=h2

command_name=$0
function print_usage {
  echo "Usage: " `basename $command_name` "[WAR_FILE] [ARG]..." 1>&2
  echo "where ARG can be one of the following:" 1>&2
  echo "    h2         - configure to use the h2 backend on the local filesystem" 1>&2
  echo "    postgresql - configure to use the postgresql backend installed on localhost" 1>&2
  echo "    mongo      - configure to use the mongo backend installed on localhost" 1>&2
  echo "    customjdbc - configure to use the custom postgres-specific JDBc adapter on localhost" 1>&2
  echo "" 1>&2
}

if [ "$1" == "--help" ]; then
  print_usage
  exit 0
else
  AH_FILE="$1"
fi

if [ "$2" == "h2" ]; then
  CONF=h2
elif [ "$2" == "postgresql" ]; then
  CONF=postgresql
elif [ "$2" == "mongo" ]; then
  CONF=mongo
elif [ "$2" == "customjdbc" ]; then
  CONF=customjdbc
fi

### calculate variables and urls
source ./catalina-vars.sh

### log the setup attempt
log "install-ah-2.sh - SRC=$SRC, CONF=$CONF, AH_FILE=$AH_FILE"

service tomcat7 stop
java -jar jetty-killer.jar &>/dev/null    # shutdown any ah jetty
sleep 3

# clean out the database
./blitz-ah.sh no-restart-tomcat

### tear down any previous versions

# uninstall any rpm
yum erase -y -q atomhopper.noarch

# uninstall any WAR file
rm -rf $CATALINA_HOME/webapps/ROOT.war
rm -rf $CATALINA_HOME/webapps/ROOT

# delete left-over config files
rm -rf /etc/atomhopper
rm -rf /opt/atomhopper
rm -rf /var/log/atomhopper

mkdir -p /etc/atomhopper
mkdir -p /opt/atomhopper
mkdir -p /var/log/atomhopper
chown -R tomcat:tomcat /etc/atomhopper /opt/atomhopper /var/log/atomhopper

mv $AH_FILE $CATALINA_HOME/webapps/
rm -rf $CATALINA_HOME/webapps/ROOT/
mv $CATALINA_HOME/webapps/$AH_FILE $CATALINA_HOME/webapps/ROOT.war

chmod 755 /opt/atomhopper

### copy config files
./conf.pl $CONF --no-restart-tomcat --param hostname=`./calc-ip.sh`

# start up
service tomcat7 start

sleep 3
curl -s localhost:8080/namespace/feed


