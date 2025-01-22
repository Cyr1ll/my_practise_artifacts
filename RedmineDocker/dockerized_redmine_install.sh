#!/bin/bash

set -e  # Остановить выполнение при ошибке

# ==== Конфигурационные параметры ====
REDMINE_VERSION="5.0.5"
DB_ROOT_PASSWORD="root_password"
DB_NAME="redmine"
DB_USER="redmine_user"
DB_PASSWORD="redmine_password"

# ==== Установка Docker и Docker Compose ====
echo "🔧 Устанавливаем Docker и Docker Compose..."
apt update
apt install -y docker.io docker-compose

# ==== Создание папок для проекта ====
echo "🔧 Создаём структуру проекта..."
mkdir -p /opt/redmine-docker/{plugins,themes}

# ==== Копирование плагинов и темы ====
echo "🔧 Копируем плагины и тему..."
cp -r ~/plugins/* /opt/redmine-docker/plugins/
cp -r ~/a1 /opt/redmine-docker/themes/a1

# ==== Создание docker-compose.yml ====
echo "🔧 Создаём docker-compose.yml..."
cat > /opt/redmine-docker/docker-compose.yml <<EOF
version: '3.8'

services:
  mariadb:
    image: mariadb:10.5
    container_name: mariadb
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    volumes:
      - mariadb_data:/var/lib/mysql

  redmine:
    image: redmine:$REDMINE_VERSION
    container_name: redmine
    restart: always
    depends_on:
      - mariadb
    environment:
      REDMINE_DB_MYSQL: mariadb
      REDMINE_DB_DATABASE: $DB_NAME
      REDMINE_DB_USERNAME: $DB_USER
      REDMINE_DB_PASSWORD: $DB_PASSWORD
    ports:
      - "8080:3000"
    volumes:
      - ./plugins:/usr/src/redmine/plugins
      - ./themes:/usr/src/redmine/public/themes

volumes:
  mariadb_data:
EOF

# ==== Запуск контейнеров ====
echo "🚀 Запускаем Redmine и MariaDB..."
cd /opt/redmine-docker
docker-compose up -d

# ==== Завершение ====
echo "✅ Установка завершена! Перейдите на http://<ваш_ip>:8080 и войдите в систему."

