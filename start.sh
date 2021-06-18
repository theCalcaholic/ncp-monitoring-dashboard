. .env

export NEXTCLOUD_SERVER
export NCP_METRICS_USER
export NCP_METRICS_PASSWORD
export NEXTCLOUD_HOST="${NEXTCLOUD_SERVER#http*:\/\/*}"

envsubst < config/prometheus/prometheus.tmpl > config/prometheus/prometheus.yml
docker-compose up