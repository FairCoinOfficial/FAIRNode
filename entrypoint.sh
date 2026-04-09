#!/bin/bash
set -e

CONF_DIR="/home/faircoin/.faircoin"
CONF_FILE="$CONF_DIR/faircoin.conf"

mkdir -p "$CONF_DIR"

if [ ! -f "$CONF_FILE" ]; then
    RPC_PASS=$(head -c 32 /dev/urandom | base64 | tr -d '=+/' | head -c 32)
    cat > "$CONF_FILE" <<EOF
rpcuser=faircoinrpc
rpcpassword=${RPC_PASS}
server=1
listen=1
daemon=0
printtoconsole=1
EOF
    echo "[entrypoint] Generated new faircoin.conf with random RPC password"
    echo "[entrypoint] RPC user: faircoinrpc"
    echo "[entrypoint] RPC pass: ${RPC_PASS}"
fi

chown -R faircoin:faircoin "$CONF_DIR"

exec gosu faircoin "$@"
