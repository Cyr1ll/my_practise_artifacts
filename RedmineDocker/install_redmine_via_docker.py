import os
import subprocess

# ==== Конфигурационные параметры ====
REDMINE_VERSION = "5.0.5"
DB_ROOT_PASSWORD = "root_password"
DB_NAME = "redmine"
DB_USER = "redmine_user"
DB_PASSWORD = "redmine_password"
BASE_DIR = "/opt/redmine-docker"

def run_command(command):
    """Выполняет команду и завершает скрипт при ошибке."""
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"Ошибка выполнения команды: {command}")
        exit(1)

def install_docker():
    """Установка Docker и Docker Compose."""
    print("🔧 Устанавливаем Docker и Docker Compose...")
    run_command("apt update")
    run_command("apt install -y docker.io docker-compose")

def setup_project_structure():
    """Создание папок для проекта."""
    print("🔧 Создаём структуру проекта...")
    os.makedirs(f"{BASE_DIR}/plugins", exist_ok=True)
    os.makedirs(f"{BASE_DIR}/themes", exist_ok=True)

    print("🔧 Копируем плагины и тему...")
    run_command(f"cp -r ~/plugins/* {BASE_DIR}/plugins/")
    run_command(f"cp -r ~/a1 {BASE_DIR}/themes/a1")

def create_docker_compose():
    """Создание файла docker-compose.yml."""
    print("🔧 Создаём docker-compose.yml...")
    compose_content = f"""
version: '3.8'

services:
  mariadb:
    image: mariadb:10.5
    container_name: mariadb
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: {DB_ROOT_PASSWORD}
      MYSQL_DATABASE: {DB_NAME}
      MYSQL_USER: {DB_USER}
      MYSQL_PASSWORD: {DB_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql

  redmine:
    image: redmine:{REDMINE_VERSION}
    container_name: redmine
    restart: always
    depends_on:
      - mariadb
    environment:
      REDMINE_DB_MYSQL: mariadb
      REDMINE_DB_DATABASE: {DB_NAME}
      REDMINE_DB_USERNAME: {DB_USER}
      REDMINE_DB_PASSWORD: {DB_PASSWORD}
    ports:
      - "8080:3000"
    volumes:
      - ./plugins:/usr/src/redmine/plugins
      - ./themes:/usr/src/redmine/public/themes

volumes:
  mariadb_data:
    """
    with open(f"{BASE_DIR}/docker-compose.yml", "w") as f:
        f.write(compose_content)

def start_docker_compose():
    """Запуск Docker Compose."""
    print("🚀 Запускаем Redmine и MariaDB...")
    run_command(f"cd {BASE_DIR} && docker-compose up -d")

def main():
    install_docker()
    setup_project_structure()
    create_docker_compose()
    start_docker_compose()
    print("✅ Установка завершена! Перейдите на http://<ваш_ip>:8080 и войдите в систему.")

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("Этот скрипт должен быть запущен с правами root.")
        exit(1)
    main()

