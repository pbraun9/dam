#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/?pretty" -u $user:$passwd

