#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/mongodb-setup.log) 2>&1

echo "Starting MongoDB deployment"

export DEBIAN_FRONTEND=noninteractive
export AWS_DEFAULT_REGION=us-east-1

apt-get update -y
apt-get install -y docker.io curl unzip
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

cd /tmp
unzip -q -o awscliv2.zip
./aws/install

aws --version
systemctl enable --now docker

mkdir -p /opt/mongodb
chmod 700 /opt/mongodb

echo "Retrieving MongoDB credentials from SSM"

# Allow time for the EC2 IAM role to become available
for attempt in $(seq 1 20); do
  if MONGO_PASSWORD=$(aws ssm get-parameter \
    --name "/startuptech/mongodb/password" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text 2>/dev/null); then
    break
  fi
  sleep 15
done

if [ -z "${MONGO_PASSWORD:-}" ]; then
  echo "ERROR: Unable to retrieve MongoDB credentials"
  exit 1
fi

umask 077

printf 'MONGO_INITDB_ROOT_USERNAME=muchtodo_admin\n' \
  > /opt/mongodb/mongo.env

printf 'MONGO_INITDB_ROOT_PASSWORD=%s\n' "$MONGO_PASSWORD" \
  >> /opt/mongodb/mongo.env

unset MONGO_PASSWORD

docker volume create muchtodo_mongodb_data

docker run -d \
  --name muchtodo-mongodb \
  --restart unless-stopped \
  --env-file /opt/mongodb/mongo.env \
  -p 27017:27017 \
  -v muchtodo_mongodb_data:/data/db \
  mongo:8.0

echo "MongoDB container started successfully"
