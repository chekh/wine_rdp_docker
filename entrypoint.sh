#!/usr/bin/env bash

# Retrieve the password from an environment variable
groupadd --gid 1020 "$SERVICE_GROUP"

# Use the password in your commands
useradd --shell /bin/bash \
        --uid 1020 --gid 1020 \
        --password "$(openssl passwd "$PASSWORD")" \
        --create-home \
        --home-dir "/home/$SERVICE_USER" "$SERVICE_USER"

usermod -aG sudo "$SERVICE_USER"

# Start xrdp sesman service
/usr/sbin/xrdp-sesman
/usr/sbin/xrdp --nodaemon
