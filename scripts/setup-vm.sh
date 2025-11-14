#!/usr/bin/env bash
set -e


# Example bootstrap for Debian/Ubuntu
sudo apt-get update
sudo apt-get upgrade -y


# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER


# docker-compose
sudo apt-get install -y docker-compose


# nginx
sudo apt-get install -y nginx
sudo systemctl enable --now nginx


# create deploy user
if ! id -u deploy >/dev/null 2>&1; then
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /home/deploy/.ssh
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
echo "Add your public key to /home/deploy/.ssh/authorized_keys"
fi


sudo mkdir -p /opt/ecom-app
sudo chown deploy:deploy /opt/ecom-app


# Drop nginx config (requires review before enabling)
sudo cp nginx/ecom.conf /etc/nginx/sites-available/ecom.conf
sudo ln -sf /etc/nginx/sites-available/ecom.conf /etc/nginx/sites-enabled/ecom.conf
sudo nginx -t
sudo systemctl reload nginx


echo "Bootstrap complete. Add deploy public key to /home/deploy/.ssh/authorized_keys and copy docker-compose.yml to /opt/ecom-app"
