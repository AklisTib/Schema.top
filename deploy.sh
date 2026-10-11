#!/bin/bash
set -e


apt update && apt upgrade -y
apt install -y nodejs npm mariadb-server curl

rm -rf /var/www/html
find /var/www -type f -name "*.html" -delete 2>/dev/null || true
find /usr/share/nginx -type f -name "*.html" -delete 2>/dev/null || true

a2dissite 000-default.conf 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true
apt purge -y apache2 apache2-utils apache2-bin apache2-data
apt autoremove -y


apt install -y nginx
systemctl enable --now nginx


apt install -y ufw
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 2024/tcp
ufw --force enable
systemctl restart ufw


mkdir -p /var/www/schema
chown -R www-data:www-data /var/www/schema

cat > /etc/nginx/sites-available/schema <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name schema;

    root /var/www/schema;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

ln -sf /etc/nginx/sites-available/schema /etc/nginx/sites-enabled/schema
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx


apt install -y certbot python3-certbot-nginx


systemctl enable --now certbot.timer 2>/dev/null || true
certbot renew --dry-run