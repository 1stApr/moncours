#!/bin/bash
#

# update sources
sudo apt-get update

# install mariadb
sudo apt-get -y install mariadb-server

# create database
mariadb -u root -e "CREATE DATABASE %DATABASE%"
mariadb -u root -e "GRANT ALL PRIVILEGES ON %DATABASE%.* TO '%USERNAME%'@'localhost' IDENTIFIED BY '%PASSWORD%'"

# hardening mariadb
mariadb -u root -e "DELETE FROM mysql.global_priv WHERE User=''"
mariadb -u root -e "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mariadb -u root -e "DROP DATABASE IF EXISTS test"
mariadb -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
mariadb -u root -e "FLUSH PRIVILEGES"

# set root password
mysqladmin --user root password '%PASSWORD%'

