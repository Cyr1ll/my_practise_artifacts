#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Updating system packages..."
sudo apt update
sudo apt install -y git curl postgresql postgresql-contrib

echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

echo "Loading NVM..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "Installing Node.js..."
nvm install 16

echo "Setting up PostgreSQL..."
sudo -i -u postgres psql <<EOF
CREATE ROLE project_user WITH SUPERUSER LOGIN PASSWORD 'yourpassword';
CREATE DATABASE project_db OWNER project_user;
EOF

echo "Configuring PostgreSQL authentication..."
POSTGRES_VERSION=$(psql --version | grep -oP '\d+(\.\d+)+')
sudo sed -i "/local\s*all\s*postgres\s*peer/a\local all project_user peer" /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf
sudo systemctl restart postgresql

echo "Cloning repositories..."
mkdir -p project
cd project
git clone https://github.com/n4x15/vue-todo
git clone https://github.com/n4x15/vue-todo-api

echo "Setting up vue-todo-api..."
cd vue-todo-api
mv .env.example .env
sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://project_user:yourpassword@localhost:5432/project_db|" .env
sed -i "s|PORT=.*|PORT=3000|" .env
sed -i "s|JWT_SECRET=.*|JWT_SECRET=secret|" .env
npm install
npm run migration:run
npm run start &
cd ..

echo "Setting up vue-todo frontend..."
cd vue-todo
mv .env.example .env
sed -i "s|VITE_API_URL=.*|VITE_API_URL=http://localhost:3000|" .env
npm install
npm run dev &

echo "Application is running. Frontend: http://localhost:3000"

