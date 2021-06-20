#!/usr/bin/env bash

set -e

PATH="$PATH:$HOME/.local/bin"
COMPOSE_CMD="docker-compose"

if ! command -v docker > /dev/null
then
  echo "docker could not be found."
  read -r -N 1 -p "Should it be installed now (requires root/sudo privileges)? (y|N)" choice
  [[ "${choice,,}" == "y" ]] || {
    echo "Exiting..."
    exit 1
  }

  tmp_file="$(mktemp)"
  curl -fsSL https://get.docker.com -o "$tmp_file"
  sh "$tmp_file"
fi



needs_compose=0
if ! command -v $COMPOSE_CMD > /dev/null
then
  echo "docker-compose not found."
  needs_compose=1
elif ! docker-compose config > /dev/null 2>&1
then
  echo "Installed docker-compose is too old (incompatible)."
  needs_compose=1
fi

if [[ $needs_compose -eq 1 ]]
then
  echo "Getting latest version of docker-compose..."
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o ./docker-compose
  chmod +x ./docker-compose
  COMPOSE_CMD="./docker-compose"
fi

. .env

if [[ -z "$NEXTCLOUD_SERVER" ]] || [[ -z "$NEXTCLOUD_USERNAME" ]] \
  || [[ -z "$NEXTCLOUD_PASSWORD" ]] || [[ -z "$NCP_METRICS_USERNAME" ]] \
  || [[ -z "$NCP_METRICS_PASSWORD" ]]
then
  echo "Please fill the variables in .env before executing this script."
  exit 1
fi

export NEXTCLOUD_SERVER
export NCP_METRICS_USERNAME
export NCP_METRICS_PASSWORD
export NEXTCLOUD_HOST="${NEXTCLOUD_SERVER#http*:\/\/*}"

echo ""

envsubst < config/prometheus/prometheus.tmpl > config/prometheus/prometheus.yml
$COMPOSE_CMD up -d

echo ""
echo "Services are starting up. In the future you can start them by executing '$COMPOSE_CMD -d up' and stop them by executing "$COMPOSE_CMD down" from this directory."
echo "You can reach Grafana at https://localhost:3000"
echo ""

read -r -N 1 -p "Show logs? (Y|n)" choice
[[ "${choice,,}" == "n" ]] || $COMPOSE_CMD logs -f --tail="all"
