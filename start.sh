#!/usr/bin/env bash
set -e

SSH_USER="${SSH_USER:-dev}"
SSH_PASS="${SSH_PASS:-changeme}"
VNC_PASS="${VNC_PASS:-changeme}"
WEB_USER="${WEB_USER:-admin}"
WEB_PASS="${WEB_PASS:-admin}"

# Гарантируем наличие папок на случай перезапуска
mkdir -p /etc/sudoers.d
mkdir -p /etc/x11vnc
mkdir -p /home/$SSH_USER

# Создаем пользователя, если его нет
if ! id "$SSH_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$SSH_USER"
    echo "$SSH_USER:$SSH_PASS" | chpasswd
    echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$SSH_USER"
    chmod 0440 "/etc/sudoers.d/$SSH_USER"
else
    echo "$SSH_USER:$SSH_PASS" | chpasswd
fi

# Права на домашнюю папку (чтобы XFCE мог писать конфиги)
chown -R $SSH_USER:$SSH_USER /home/$SSH_USER

# Сохраняем пароль VNC
x11vnc -storepasswd "$VNC_PASS" /etc/x11vnc/passwd >/dev/null 2>&1

# Создаем пароль для веб-интерфейса (Basic Auth)
htpasswd -bc /etc/nginx/.htpasswd "$WEB_USER" "$WEB_PASS" >/dev/null 2>&1

echo "=== Настройка завершена. Запуск supervisord... ==="
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
