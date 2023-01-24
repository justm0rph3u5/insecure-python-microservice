#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt update && apt install nginx jq -y
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xvzf ngrok-v3-stable-linux-amd64.tgz && mv ngrok /usr/local/bin/
ngrok config add-authtoken 2KmmwsI7Q5qlKbKWTjGZ9E899Hx_55oJbkjaQSkKJoLRypa1d
unlink /etc/nginx/sites-enabled/default
cp /home/ubuntu/insecure-python-microservice/infrastructure/ansible/reverse-proxy.conf /etc/nginx/sites-available/reverse-proxy.conf
ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
service nginx restart
sleep 1;
