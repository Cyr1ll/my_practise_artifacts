import os
import subprocess

def run_command(command):
    """Execute shell commands."""
    print(f"Running: {command}")
    subprocess.run(command, shell=True, check=True)

# Step 1: Update system and install prerequisites
print("Обновление системы и установка пакетов...")
run_command("sudo apt update")
run_command("sudo apt install -y git curl apt-transport-https ca-certificates software-properties-common")

# Step 2: Install Docker
print("Установка Docker...")
run_command("sudo mkdir -p /etc/apt/keyrings")
run_command("curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg")
run_command("echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null")
run_command("sudo apt update")
run_command("sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin")

# Step 3: Add current user to Docker group
print("Добавление пользователя в группу Docker...")
run_command(f"sudo usermod -aG docker {os.getlogin()}")

# Step 4: Install Docker Compose
print("Установка Docker Compose...")
run_command("sudo curl -L 'https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose")
run_command("sudo chmod +x /usr/local/bin/docker-compose")
run_command("docker-compose --version")

# Step 5: Clone repositories
print("Клонирование репозиториев...")
os.makedirs("project", exist_ok=True)
os.chdir("project")
run_command("git clone https://github.com/n4x15/vue-todo")
run_command("git clone https://github.com/n4x15/vue-todo-api")

# Step 6: Write Dockerfile and Compose files
print("Создание файлов Docker и Compose...")
with open("vue-todo-api/Dockerfile", "w") as f:
    f.write("""\
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
""")

with open("vue-todo/Dockerfile", "w") as f:
    f.write("""\
FROM node:16

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV VITE_API_URL=http://localhost:3000

CMD ["npm", "run", "dev"]
""")

with open("docker-compose.yml", "w") as f:
    f.write("""\
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
      VITE_API_URL=http://localhost:3000
    depends_on:
      - api
    ports:
      - "3001:3000"

volumes:
  postgres_data:
""")

# Step 7: Deploy with Docker Compose
print("Запуск приложения через Docker Compose...")
run_command("docker-compose up --build -d")

print("Приложение развернуто!")
print("Frontend: http://localhost:3001")
print("API: http://localhost:3000")

