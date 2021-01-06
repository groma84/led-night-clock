#!/bin/bash
export MIX_TARGET=rpi4 && mix firmware && ./upload.sh nightclock.local
