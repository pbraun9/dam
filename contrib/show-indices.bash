#!/bin/bash

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_cat/indices?s=index" -u $admin_user:$admin_passwd

