#!/bin/bash

apt update

# Install MySQL
apt update
apt install mysql-server
systemctl start mysql.service

# Install AWS CLI
apt install -y awscli
