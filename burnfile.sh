#!/usr/bin/env bash

set -o errtrace                                     # If set, the ERR trap is inherited by shell functions.
set -o errexit                                      # Exit immediately if a command exits with a non-zero status.
set -o nounset                                      # Treat unset variables as an error when substituting.
set -o pipefail                                     # The return value of a pipeline is the status of the last command to exit with

/home/carl/dev/sdm/sdm --burnfile /home/carl/dev/sdm/output/rpicm4-1-out.img \
    --host rpicm4-1.1stcall.uk \
    --regen-ssh-host-keys \
    /home/carl/dev/sdm/output/rpicm4-1.img
