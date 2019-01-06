#!/bin/bash

set -eu

ROACHBIN="/cockroach/cockroach.sh"
CERTS_DIR="${COCKROACH_CERTS_DIR:-"/certs/common"}"
COCKROACH_INSECURE="${COCKROACH_INSECURE:-"TRUE"}"
COCKROACH_STORE="${COCKROACH_STORE:-"path=/data,attrs=ssd,size=10G"}"

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
  if [ "$COCKROACH_INSECURE" == "TRUE" ]; then
    _extra_opts="--insecure"
  else
    _extra_opts="--certs-dir=$CERTS_DIR"
  fi
  if [ "$PRIMARY_NODE" != "$(hostname)" ]; then
    _extra_opts="$_extra_opts --join=$PRIMARY_NODE"
  else
    ($0 wait-init)&
  fi
  exec $ROACHBIN start \
    --store="$COCKROACH_STORE" \
    --advertise-addr="$(hostname)" \
    --listen-addr="0.0.0.0" \
    $_extra_opts
fi

if [ "${1}" == "init" ]; then
  echo "============ INIT cockroachdb"
  _extra_opts=""
  if [ "$COCKROACH_INSECURE" == "FALSE" ]; then
    _extra_opts="--certs-dir=$CERTS_DIR"
    SQL="$ROACHBIN sql --host=$PRIMARY_NODE $_extra_opts"
    $SQL -e "CREATE USER IF NOT EXISTS toor WITH PASSWORD 'password';"
  fi
fi

#EOF
