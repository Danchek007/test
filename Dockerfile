FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# --- ВАЖНО: добавили curl и ca-certificates ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb x11vnc \
    xfce4-session xfce4-terminal xfwm4 xfdesktop4 xfce4-panel \
    thunar dbus-x11 xterm \
    novnc websockify \
    openssh-server \
    nginx \
    supervisor \
    apache2-utils \
    tini \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- websocat: SSH over WebSocket ---
ARG WEBSOCAT_VERSION=v1.13.0
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) WSC="websocat.x86_64-unknown-linux-musl" ;; \
      arm64) WSC="websocat.aarch64-unknown-linux-musl" ;; \
      *) echo "unsupported arch: $ARCH"; exit 1 ;; \
    esac && \
    URL="https://github.com/vi/websocat/releases/download/${WEBSOCAT_VERSION}/${WSC}" && \
    echo "Downloading $URL" && \
    curl -fsSL "$URL" -o /usr/local/bin/websocat && \
    chmod +x /usr/local/bin/websocat && \
    /usr/local/bin/websocat --version

# --- sshd ---
RUN mkdir -p /var/run/sshd && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    printf '\nListenAddress 127.0.0.1\n' >> /etc/ssh/sshd_config

COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/services.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Koyeb/Render ждёт трафик на 8000/6080
ENV PORT=6080
EXPOSE 6080

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/start.sh"]
