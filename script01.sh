#!/usr/bin/env bash
# remove container ubc if it exists
incus ls --format=json | jq 'map(select(.name == "ubc")) | .[] | .name' | xargs --no-run-if-empty -I {} incus delete --force {}

# launch ubuntu 22.04 container and name it ubc
incus launch images:ubuntu/22.04 ubc
incus ls
