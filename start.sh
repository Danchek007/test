#!/usr/bin/env bash
set -euo pipefail

SSH_USER="${SSH_USER:-dev}"
SSH_PASS="${SSH_PASS:-changeme}"
VNC_PASS="${VNC_PASS:-changeme}"
WEB_USER="${WEB_USER:-admin}"
WEB_PASS="${WEB_PASS:-admin}"

# --- пользователь ssh ---
if ! id "$SSH_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$SSH_USER"
    echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$SSH_USER"
fi
echo "$SSH_USER:$SSH_PASS" | chpasswd

# --- VNC пароль ---
mkdir -p /etc/x11vnc
x11vnc -storepasswd "$VNC_PASS" /etc/x11vnc/passwd >/dev/null

# --- Basic Auth для /vnc/ ---
htpasswd -bc /etc/nginx/.htpasswd "$WEB_USER" "$WEB_PASS" >/dev/null

echo "[start] sshd user=$SSH_USER  web=$WEB_USER"
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
