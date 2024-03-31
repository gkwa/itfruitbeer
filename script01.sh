#!/usr/bin/env bash
# remove container ubc if it exists
lxc ls --format=json | jq 'map(select(.name == "ubc")) | .[] | .name' | xargs --no-run-if-empty -I {} lxc delete --force {}

# launch ubuntu 22.04 container and name it ubc
lxc launch ubuntu:22.04 ubc
lxc ls
