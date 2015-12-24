#!/usr/bin/env bash

# TODO: This kills _all_ containers
docker kill $(docker ps -aq)
docker rm $(docker ps -aq)