#!/bin/bash
set -e

source /etc/dam/dam.conf

curl -fsSk "$endpoint/_plugins/_ism/policies?pretty" -u $admin_user:$admin_passwd

