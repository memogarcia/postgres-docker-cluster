#!/bin/bash

CONFIG_FILE=$PGDATA/postgresql.conf

cp -f /var/cluster_configs/postgresql.conf $CONFIG_FILE


#CONFIGS= #in format variable1:value1[,variable2:value2[,...]]
#CONFIG_FILE= #path to file


echo "
#------------------------------------------------------------------------------
# AUTOGENERATED
#------------------------------------------------------------------------------
" >> $CONFIG_FILE

echo ">>> Configuring $CONFIG_FILE"
IFS=',' read -ra CONFIG_PAIRS <<< "$CONFIGS"
for CONFIG_PAIR in ${CONFIG_PAIRS[@]}
do
    IFS=':' read -ra CONFIG <<< "$CONFIG_PAIR"
    VAR="${CONFIG[0]}"
    VAL="${CONFIG[1]}"
    sed -e "s/\(^\ *$VAR\(.*\)$\)/#\1 # overrided in AUTOGENERATED section/g" $CONFIG_FILE > /tmp/config.tmp && mv -f /tmp/config.tmp $CONFIG_FILE
    echo ">>>>>> Adding config '$VAR' with value '$VAL' "
    echo "$VAR = $VAL" >> $CONFIG_FILE
done
echo ">>>>>> Result config file"
cat $CONFIG_FILE



if [ ! -d "/var/cluster_archive" ]; then
    mkdir -m 0700 /var/cluster_archive
fi
chown -R postgres /var/cluster_archive
chmod -R 0700 /var/cluster_archive

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE ROLE $REPLICATION_USER WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD' SUPERUSER CREATEDB  CREATEROLE INHERIT LOGIN;"
gosu postgres createdb $REPLICATION_DB -O $REPLICATION_USER


echo "host replication $REPLICATION_USER 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf



/usr/local/bin/cluster/repmgr_register.sh