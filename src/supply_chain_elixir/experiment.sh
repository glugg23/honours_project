#!/usr/bin/env bash

DOCKER_FILE=${1}

echo "Building Docker images and doing warmup run"

docker compose -f $DOCKER_FILE up --build --remove-orphans > /dev/null 2>&1

for i in $(seq 10)
do
    echo "Run $i"
    docker compose -f $DOCKER_FILE up > "$i.txt" 2> /dev/null
done

echo "Moving logs to ../../dissertation/charts/"

mv *.txt ../../dissertation/charts/
