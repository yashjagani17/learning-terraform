#!/bin/bash
dnf install httpd -y

cat > /var/www/html/index.html <<EOF
<h1>Hello World</h1>
<p>${db_address}</p>
<p>${db_port}</p>
EOF

sed -i 's/^Listen 80/Listen ${server_port}/' /etc/httpd/conf/httpd.conf
systemctl enable httpd
systemctl start httpd