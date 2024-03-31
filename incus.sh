#!/usr/bin/env bash

curl https://raw.githubusercontent.com/taylormonacelli/ringgem/master/install-kibbly-stable-sources-on-ubuntu.sh | sudo bash
curl https://raw.githubusercontent.com/taylormonacelli/ringgem/master/install-incus-on-ubuntu.sh | sudo bash

incus admin init --auto
