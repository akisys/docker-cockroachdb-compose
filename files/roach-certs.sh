#!/bin/bash

set -ueo pipefail

ROACHBIN="/cockroach/cockroach.sh"
COCKROACH_INSECURE="${COCKROACH_INSECURE:-"TRUE"}"

if [ "$COCKROACH_INSECURE" == "FALSE" ]; then
  CERTS_CA_PUB_DIR="${CERTS_CA_PUB_DIR:-$COCKROACH_CERTS_DIR}"
  CERTS_CA_PRIV_DIR="${CERTS_CA_PRIV_DIR:-$COCKROACH_CERTS_DIR}"
  CERTS_NODE_DIR="${CERTS_NODE_DIR:-$COCKROACH_CERTS_DIR}"
  CERTS_CLIENT_DIR="${CERTS_CLIENT_DIR:-$COCKROACH_CERTS_DIR}"

  mkdir -p "$CERTS_CA_PUB_DIR"
  mkdir -p "$CERTS_CA_PRIV_DIR"
  mkdir -p "$CERTS_NODE_DIR"
  mkdir -p "$CERTS_CLIENT_DIR"

  if [ ! -f "$CERTS_CA_PRIV_DIR/ca.key" ]; then
    $ROACHBIN cert create-ca \
      --certs-dir="$CERTS_CA_PUB_DIR" \
      --ca-key="$CERTS_CA_PRIV_DIR/ca.key"

    cp -f "$CERTS_CA_PUB_DIR/ca.crt" "$CERTS_NODE_DIR/ca.crt"
    cp -f "$CERTS_CA_PUB_DIR/ca.crt" "$CERTS_CLIENT_DIR/ca.crt"
  fi

  CUR_CERTS_NODES="localhost;$CERTS_NODES"
  $ROACHBIN cert create-node $(echo "$CUR_CERTS_NODES" | tr ";" " ") \
    --certs-dir="$CERTS_NODE_DIR" \
    --ca-key="$CERTS_CA_PRIV_DIR/ca.key" \
    --overwrite

  for _client in $(echo "$CERTS_CLIENTS" | tr ";" "\n");
  do
    $ROACHBIN cert create-client "$_client" \
      --certs-dir="$CERTS_CLIENT_DIR" \
      --ca-key="$CERTS_CA_PRIV_DIR/ca.key" \
      --overwrite
  done

  $ROACHBIN cert list --certs-dir="$CERTS_CA_PUB_DIR"
  $ROACHBIN cert list --certs-dir="$CERTS_NODE_DIR"
  $ROACHBIN cert list --certs-dir="$CERTS_CLIENT_DIR"

fi

if [ -z "$(which nc)" ]; then
  apt-get update && apt-get install -y netcat
fi
# run this container with minimal overhead
while true; do
  nc -l -p 8081 -q0
done
#EOF
