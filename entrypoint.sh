#!/usr/bin/env bash
set -e

# Restore known_hosts into tmpfs (build-time copy is wiped by tmpfs mount)
mkdir -p ~/.ssh
cp ~/known_hosts.bak ~/.ssh/known_hosts

# Set up SSH key if provided via Docker secret
if [ -f /run/secrets/ssh_private_key ] && [ -s /run/secrets/ssh_private_key ]; then
  cp /run/secrets/ssh_private_key ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
fi

# Lock down ~/.ssh
chmod 444 ~/.ssh/known_hosts
[ -f ~/.ssh/id_rsa ] && chmod 400 ~/.ssh/id_rsa
chmod 500 ~/.ssh

# Set git identity from env vars
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
fi

exec claude "$@"
