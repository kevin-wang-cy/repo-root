#!/bin/bash

# load variables
source .env
export $(grep --regexp ^[A-Z] .env | cut -d= -f1)

# Bring up nexus3 cluster
docker-compose up -d --build

NEXUS_PORT="${EXPOSED_NEXUS_PORT:="55443"}"

# waiting for nexus server up
until curl --fail --insecure https://localhost:$NEXUS_PORT; do 
  sleep 5
done

# read initial admin password
ADMIN_NAME="admin"
ADMIN_PASSWORD="$(cat ./nexus-data/admin.password)"

# create docker proxy
curl -v -u $ADMIN_NAME:$ADMIN_PASSWORD --insecure --header 'Content-Type: application/json' https://localhost:$NEXUS_PORT/service/rest/v1/script -d @init-data/create-docker-proxy.json
curl -v -X POST -u $ADMIN_NAME:$ADMIN_PASSWORD --insecure --header 'Content-Type: text/plain' https://localhost:$NEXUS_PORT/service/rest/v1/script/CreateDockerProxy/run

# change amdin password
ADMIN_NEWPASSWORD="${ADMIN_NEWPASSWORD:="Rdis2fun"}"

curl -v -u $ADMIN_NAME:$ADMIN_PASSWORD --insecure -X PUT "https://localhost:$NEXUS_PORT/service/rest/beta/security/users/admin/change-password" -H "accept: application/json" -H "Content-Type: text/plain" -d "$ADMIN_NEWPASSWORD"