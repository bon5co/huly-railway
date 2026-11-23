#!/bin/bash
# Elasticsearch 7.14 (the version Huly's full-text service is built against) on a root-owned Railway volume.
set -eu
ES=/usr/share/elasticsearch
DATA="$ES/data"
mkdir -p "$DATA" "$ES/logs"
chown -R 1000:0 "$DATA" "$ES/logs"
echo "[huly] elastic data owner=$(stat -c %u:%g "$DATA")"
HEAP="${ES_HEAP:-1024m}"
export ES_JAVA_OPTS="-Xms$HEAP -Xmx$HEAP"
exec setpriv --reuid=1000 --regid=0 --clear-groups env "discovery.type=single-node" "ES_JAVA_OPTS=$ES_JAVA_OPTS" "ELASTICSEARCH_PORT_NUMBER=9200" /usr/local/bin/docker-entrypoint.sh eswrapper
