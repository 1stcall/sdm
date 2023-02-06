#!/usr/bin/env bash

set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
set -o nounset                                      # Treat unset variables as an error when substituting.
set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with

declare baseDirectory="/home/carl/dev/sdm"
declare baseImage="2022-09-22-raspios-bullseye-arm64-lite.img"
declare baseImageDirectory="baseos"
declare hostName="rpicm4-1"

/home/carl/dev/sdm/sdm --burnfile /home/carl/dev/sdm/output/rpicm4-1-out.img \
    --host rpicm4-1.1stcall.uk \
    --regen-ssh-host-keys \
    --fstab ${baseDirectory}/my-fstab \
    /home/carl/dev/sdm/output/rpicm4-1.img
