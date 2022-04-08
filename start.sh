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

if [[ -z "$NEXTCLOUD_SERVER" ]] \
  || [[ (-z "$NEXTCLOUD_USERNAME" || -z "$NEXTCLOUD_PASSWORD") && -z "$NEXTCLOUD_AUTH_TOKEN" ]] \
  || [[ -z "$NCP_METRICS_USERNAME" ]] \
  || [[ -z "$NCP_METRICS_PASSWORD" ]]
then
  echo "Please fill the variables in .env before executing this script."
  exit 1
fi

export NEXTCLOUD_SERVER
export NCP_METRICS_USERNAME
export NCP_METRICS_PASSWORD
export NEXTCLOUD_HOST="${NEXTCLOUD_SERVER#http*:\/\/*}"
export DOCKER_COMPOSE_CMD="$(realpath "$(which "${COMPOSE_CMD}")")"
export WORKING_DIRECTORY="$(pwd)"

echo ""

envsubst < config/prometheus/prometheus.tmpl > config/prometheus/prometheus.yml

set -x

if [ "$EUID" -eq 0 ]
then
  echo ""
  read -r -N 1 -p "Do you want to install ncp-monitoring-dashboard as a systemd service? This is ideal for persistent hosting. (y|N)" choice
  echo ""
  if [[ "${choice,,}" == "y" ]]
    then
    chown -R root: .
    chmod 600 .env
    envsubst < config/systemd/ncp-monitoring-dashboard.service.tmpl > /etc/systemd/system/ncp-monitoring-dashboard.service
    systemctl daemon-reload
    systemctl enable ncp-monitoring-dashboard
    START_CMD=(systemctl start ncp-monitoring-dashboard)
    STOP_CMD=(systemctl stop ncp-monitoring-dashboard)
    SHOW_LOGS_CMD=(journalctl -fu ncp-monitoring-dashboard)
  fi
else
  echo "Skipping systemd service installation. Reason: Must be root"
fi

[[ -n "${START_CMD[*]}" ]] || {
  START_CMD=("$COMPOSE_CMD" up -d)
  STOP_CMD=("$COMPOSE_CMD" down)
  SHOW_LOGS_CMD=("$COMPOSE_CMD" logs -f --tail='all')
}

"${START_CMD[@]}"
[[ -f config/nginx/cert/private_key.pem ]] || {
  mkdir -p config/nginx/cert
  openssl req -x509 -newkey rsa:4096 \
    -keyout config/nginx/cert/private_key.pem \
    -out config/nginx/cert/certificate.pem \
    -sha256 -days 365 -nodes -subj "/CN=${1:-localhost}"
}


echo ""
echo "Services are starting up. In the future you can start them by executing '${START_CMD[*]}' and stop them by executing '${STOP_CMD[*]}' from this directory."
echo "You can reach Grafana at https://localhost:8443"
echo ""

read -r -N 1 -p "Show logs? (Y|n)" choice
[[ "${choice,,}" == "n" ]] || "${SHOW_LOGS_CMD[@]}"
