#!/usr/bin/env bash
# Usage: deploy.sh <image-tag> <remote-dir>
IMAGE_TAG="$1"
REMOTE_DIR="${2:-/opt/ecom-app}"


if [ -z "$IMAGE_TAG" ]; then
echo "usage: $0 <image-tag> [remote-dir]"
exit 1
fi


cat > /tmp/docker-compose.yml <<EOF
version: "3.8"
services:
ecom-app:
image: ${IMAGE_TAG}
restart: always
ports:
- "127.0.0.1:8080:8080"
environment:
- JAVA_OPTS=-Xmx512m
EOF


mv /tmp/docker-compose.yml $REMOTE_DIR/docker-compose.yml
cd $REMOTE_DIR
docker-compose pull || true
docker-compose up -d --remove-orphans