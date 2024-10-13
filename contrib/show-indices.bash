#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/indices?s=index" -u $user:$passwd

