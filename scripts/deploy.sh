#!/bin/bash
set +o xtrace


echo "Deploy start"

cd ../cnc-web-tier
docker build -t dod-cnc/cnc-webapp .
ecs-cli push dod-cnc/cnc-webapp:latest

cd ../cnc-app-tier
docker build -t dod-cnc/cnc-geoserver .
ecs-cli push dod-cnc/cnc-geoserver:latest


echo "Deploy done"

