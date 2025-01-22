#!/bin/bash

set -e  # Остановить скрипт при ошибке

echo "Обновление системы и установка необходимых пакетов..."
sudo apt update
sudo apt install -y git curl apt-transport-https ca-certificates software-properties-common

echo "Установка Docker..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Добавление текущего пользователя в группу Docker..."
sudo usermod -aG docker $USER

echo "Установка Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Клонирование репозиториев приложения..."
mkdir -p project && cd project
git clone https://github.com/n4x15/vue-todo
git clone https://github.com/n4x15/vue-todo-api

echo "Создание Dockerfile для API..."
cat > vue-todo-api/Dockerfile <<EOL
FROM node:16

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV DATABASE_URL=postgresql://project_user:yourpassword@db:5432/project_db
ENV PORT=3000
ENV JWT_SECRET=secret

RUN npm run migration:run

CMD ["npm", "run", "start"]
EOL

echo "Создание Dockerfile для Frontend..."
cat > vue-todo/Dockerfile <<EOL
FROM node:16

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV VITE_API_URL=http://localhost:3000

CMD ["npm", "run", "dev"]
EOL

echo "Создание docker-compose.yml..."
cat > docker-compose.yml <<EOL
version: "3.9"
services:
  db:
    image: postgres:14
    environment:
      POSTGRES_USER: project_user
      POSTGRES_PASSWORD: yourpassword
      POSTGRES_DB: project_db
    volumes:
      - postgres_data:/var/lib/postgresql/data

  api:
    build:
      context: ./vue-todo-api
    environment:
      DATABASE_URL: postgresql://project_user:yourpassword@db:5432/project_db
      PORT: 3000
      JWT_SECRET: secret
    depends_on:
      - db
    ports:
      - "3000:3000"

  frontend:
    build:
      context: ./vue-todo
    environment:
      VITE_API_URL: http://localhost:3000
    depends_on:
      - api
    ports:
      - "3001:3000"

volumes:
  postgres_data:
EOL

echo "Запуск приложения с помощью Docker Compose..."
docker-compose up --build -d

echo "Приложение развернуто!"
echo "Frontend: http://localhost:3001"
echo "API: http://localhost:3000"

