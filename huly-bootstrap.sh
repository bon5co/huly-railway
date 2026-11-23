#!/bin/bash
# Idempotent: creates the administrator and a first workspace through the account service, from the gateway's own variables.
# Sign-up stays closed (DISABLE_SIGNUP on the account service); this uses the maintenance tool shipped in the same image.
set -u
R=railway.internal
ACCOUNTS="http://account.$R:3000"
J="content-type: application/json"
export SERVER_SECRET="$SECRET"
export DB_URL="postgres://selfhost:$CR_PASSWORD@cockroach.$R:26257/defaultdb"
export ACCOUNT_DB_URL="$DB_URL"
export ACCOUNTS_URL="$ACCOUNTS"
export TRANSACTOR_URL="ws://transactor.$R:3333"
export STORAGE_CONFIG="minio|minio.$R?accessKey=$MINIO_ROOT_USER&secretKey=$MINIO_ROOT_PASSWORD"
cd /usr/src/app

call() { # method params [token]
  curl -s -m 30 -X POST "$ACCOUNTS/" -H "$J" ${3:+-H "authorization: Bearer $3"} -d "{\"method\":\"$1\",\"params\":$2}"
}
token() {
  call login "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p'
}

until (exec 3<>"/dev/tcp/account.$R/3000") 2>/dev/null; do sleep 3; done
echo "[huly] account service is listening"

n=0
TOKEN=""
while [ -z "$TOKEN" ]; do
  TOKEN="$(token)"
  if [ -z "$TOKEN" ]; then
    n=$((n + 1))
    [ "$n" -le 120 ] || { echo "[huly] ERROR: could not create or log in the administrator" >&2; exit 1; }
    node bundle.js create-account "$ADMIN_EMAIL" -p "$ADMIN_PASSWORD" -f Admin -l User 2>&1 | grep -E "creating account|AlreadyExists" | head -2
    sleep 5
  fi
done
echo "[huly] administrator can log in"

if ! call getUserWorkspaces '{}' "$TOKEN" | grep -q '"uuid"'; then
  call createWorkspace '{"workspaceName":"Main"}' "$TOKEN" | cut -c1-200
  echo "[huly] workspace requested"
fi
echo "[huly] bootstrap done"
