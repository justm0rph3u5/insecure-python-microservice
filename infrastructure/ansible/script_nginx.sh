#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt update && apt install nginx jq -y
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xvzf ngrok-v3-stable-linux-amd64.tgz && mv ngrok /usr/local/bin/
ngrok config add-authtoken 2KmmwsI7Q5qlKbKWTjGZ9E899Hx_55oJbkjaQSkKJoLRypa1d
unlink /etc/nginx/sites-enabled/default
cat <<EOF > /etc/nginx/sites-available/reverse-proxy.conf
server {
    listen       7777;
    server_name  localhost;

    location / {
        proxy_pass https://Worker-1:30033/;

    }

    location /webui {
        proxy_pass http://Worker-1:8080/;

    }
}
EOF
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
service nginx restart
sleep 1;
