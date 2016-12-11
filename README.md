# Dockerized Wordpress + FPM7 + Nginx + MariaDB

A docker compose that installs wordpress 4.6.1, php-fpm 7.0.11, nginx and mariadb storage

This project is based on [Tomaž Zaman work](https://codeable.io/wordpress-developers-intro-to-docker-part-two/)
Because we decide to use nginx instead of apache, it's necessary to create a "custom" wordpress container. This container uses php-fpm as base image and intalls the required packages for running nginx and basic wordpress plugins.

## Environment variables

Environment variables are defined in .env file

## Load database dumps	

For loading database dumps, sql file must be located in docker-entrypoint-initdb.d folder. Once the mysql container starts, the sql script will be executed




