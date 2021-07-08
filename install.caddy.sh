CADDY_VERSION=2.4.3
wget https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz
tar -xf caddy_${CADDY_VERSION}_linux_amd64.tar.gz

cp caddy /usr/bin/caddy


if id caddy &>/dev/null; then
    echo 'caddy user already exists'
else
    useradd --shell /bin/false --home-dir /etc/caddy --system caddy
fi


setcap cap_net_bind_service+ep /usr/bin/caddy

DIRS=(
    /var/services
    /var/log/caddy
    /etc/caddy/.config
    /etc/caddy/.local
)

for dir in ${DIRS[@]}; do
    if [ ! -d ${dir} ]; then
        mkdir -p ${dir}
    fi
    chown caddy:caddy $dir
done


cat <<EOT > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy web server
After=network-online.target

[Service]
User=caddy
Group=caddy
Type=exec
WorkingDirectory=/var/www/

ExecStart=/usr/bin/caddy run -config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload -config /etc/caddy/Caddyfile
ExecStop=/usr/bin/caddy stop

LimitNOFILE=1048576
LimitNPROC=512

PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/etc/caddy/.local /etc/caddy/.config /var/log

CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOT


cat <<EOT > /etc/caddy/Caddyfile

{
    email   support@nebulabroadcast.com
}

(security) {
    header -Server
    header / {
        Strict-Transport-Security max-age=31536000;
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy no-referrer-when-downgrade
    }
}

(error_pages) {
    handle_errors {
        rewrite * /{http.error.status_code}.html
        reverse_proxy https://error.nebulabroadcast.com
    }
}

import /var/services/*/Caddyfile
EOT


#/usr/bin/caddy run -config /etc/caddy/Caddyfile

systemctl start caddy
