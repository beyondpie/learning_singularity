#!/usr/bin/env bash

set -euo pipefail

# -d for create a directory and not a file
# -p interpret TEMPLATE relative to DIR
RSTUDIOTEMP=$(mktemp -d -p /tmp)
trap "{ rm -rf $RSTUDIOTEMP; }" EXIT

cat <<__DBCONF__ > $RSTUDIOTEMP/dbconf
provider=sqlite
directory=$RSTUDIOTEMP/db.sqlite3
__DBCONF__

export RSTUDIO_PASSWORD=password
export RSTUDIO_PORT=8889
mkdir -p $HOME/tmp
export TMPDIR=$HOME/tmp

if [[ $# > 0 ]]; then
   export RSTUDIO_PORT=$1
   if [[ ! ${RSTUDIO_PORT} =~ ^[1-9][0-9]+$ ]]; then
      >&2 echo ${RSTUDIO_PORT} is not a valid port
      exit 1
   fi
fi

printf "RStudio Username:\t$USER\n"
printf "RStudio Password:\t$RSTUDIO_PASSWORD\n"
printf "Port:\t\t\t$RSTUDIO_PORT\n"

/usr/lib/rstudio-server/bin/rserver \
	--server-working-dir $RSTUDIOTEMP \
	--server-data-dir $RSTUDIOTEMP \
	--database-config-file $RSTUDIOTEMP/dbconf \
	--server-user=$USER \
	--www-port=$RSTUDIO_PORT \
	--auth-none 0 \
	--auth-pam-helper rstudio_auth
