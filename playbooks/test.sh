#!/bin/bash

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=${SERVER_NAME}" \
  -keyout /etc/nginx/ssl/ipa.key \
  -out /etc/nginx/ssl/ipa.crt
