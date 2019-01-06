#!/bin/bash

set -eu

ROACHBIN="/cockroach/cockroach.sh"
CERTS_DIR="${COCKROACH_CERTS_DIR:-"/certs/common"}"

if [ "${1:-}" == "" ]; then
  /wait-for-it.sh roach-cert-init:8081 -s -t 60 -- $0 start
  (2> echo "Cert Init wait failed")
  exit 1
fi

if [ "${1}" == "wait-init" ]; then
  /wait-for-it.sh $PRIMARY_NODE:26257 -s -t 60 -- $0 init
  (2> echo "Start wait failed")
  exit 1
fi

if [ "${1}" == "start" ]; then
  echo "============ START cockroachdb"
  _extra_opts=""
  if [ "$PRIMARY_NODE" != "$(hostname)" ]; then
    _extra_opts="--join=$PRIMARY_NODE"
  else
    ($0 wait-init)&
  fi
  exec $ROACHBIN start \
    --certs-dir="$CERTS_DIR" \
    --advertise-addr="$(hostname)" \
    --listen-addr="0.0.0.0" \
    $_extra_opts
fi

if [ "${1}" == "init" ]; then
  echo "============ INIT cockroachdb"
  SQL="$ROACHBIN sql --certs-dir=$CERTS_DIR --host=$PRIMARY_NODE"
  $SQL -e "CREATE USER IF NOT EXISTS toor WITH PASSWORD 'password';"
fi


