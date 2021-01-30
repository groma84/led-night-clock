#!/bin/bash
export MIX_TARGET=rpi0 && source ./wifi_env.sh && mix firmware && ./upload.sh nightclock.local