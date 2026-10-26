#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/backend-setup.log) 2>&1

echo "Starting MuchTodo backend deployment"

export DEBIAN_FRONTEND=noninteractive
export AWS_DEFAULT_REGION=us-east-1

apt-get update -y
apt-get install -y docker.io python3 curl unzip

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

cd /tmp
unzip -q -o awscliv2.zip
./aws/install

aws --version

systemctl enable --now docker

mkdir -p /opt/muchtodo
chmod 700 /opt/muchtodo

echo "Retrieving application credentials from SSM"

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

if [ -z "$$${MONGO_PASSWORD:-}" ]; then
  echo "ERROR: MongoDB password retrieval failed"
  exit 1
fi

for attempt in $(seq 1 20); do
  if JWT_SECRET=$(aws ssm get-parameter \
    --name "/startuptech/backend/jwt-secret" \
    --with-decryption \
    --query "Parameter.Value" \
    --output text 2>/dev/null); then
    break
  fi
  sleep 15
done

if [ -z "$$${JWT_SECRET:-}" ]; then
  echo "ERROR: JWT secret retrieval failed"
  exit 1
fi

ENCODED_PASSWORD=$(MONGO_PASSWORD="$MONGO_PASSWORD" python3 -c \
  'import os, urllib.parse; print(urllib.parse.quote(os.environ["MONGO_PASSWORD"], safe=""))')

umask 077

{
  printf 'PORT=8080\n'
  printf 'MONGO_URI=mongodb://muchtodo_admin:%s@%s:27017/much_todo_db?authSource=admin\n' \
    "$ENCODED_PASSWORD" '${mongodb_private_ip}'
  printf 'DB_NAME=much_todo_db\n'
  printf 'JWT_SECRET_KEY=%s\n' "$JWT_SECRET"
  printf 'JWT_EXPIRATION_HOURS=72\n'
  printf 'ENABLE_CACHE=false\n'
  printf 'LOG_LEVEL=INFO\n'
  printf 'LOG_FORMAT=json\n'
  printf 'INTEGRATION=false\n'
} > /opt/muchtodo/backend.env

unset MONGO_PASSWORD ENCODED_PASSWORD JWT_SECRET

echo "Authenticating with Amazon ECR"

REGISTRY="938917088089.dkr.ecr.us-east-1.amazonaws.com"
IMAGE="$REGISTRY/startuptech-muchtodo:v1"

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$IMAGE"

docker run -d \
  --name muchtodo-backend \
  --restart unless-stopped \
  --env-file /opt/muchtodo/backend.env \
  -p 8080:8080 \
  "$IMAGE"

echo "MuchTodo backend container started successfully"
