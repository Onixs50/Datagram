#!/bin/bash

set -e

WORKDIR="$(pwd)/datagram"
CONTAINER_NAME="datagram-node"
IMAGE_NAME="datagram-cli:latest"

# Function: Check and install Docker if not present
function check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "[!] Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com | bash
    echo "[✔] Docker installed successfully."
  else
    echo "[✔] Docker is already installed."
  fi
}

# Function: Build Docker image
function build_image() {
  mkdir -p "$WORKDIR"
  cat > "$WORKDIR/Dockerfile" <<EOF
FROM ubuntu:24.04

WORKDIR /app
RUN apt-get update && apt-get install -y curl unzip && \
    curl -L https://github.com/Datagram-Group/datagram-cli-release/releases/latest/download/datagram-cli-x86_64-linux -o /app/datagram-cli && \
    chmod +x /app/datagram-cli

ENTRYPOINT ["/app/datagram-cli", "run", "--"]
EOF

  docker build -t $IMAGE_NAME "$WORKDIR"
}

# Function: Deploy Datagram node
function deploy_node() {
  read -p "Enter your Datagram key: " dkey

  check_docker
  build_image

  docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true

  docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -v "$WORKDIR:/app/data" \
    $IMAGE_NAME \
    -key "$dkey"

  echo "[✔] Node has been successfully started."
}

# Function: Show container logs
function show_logs() {
  if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    docker logs -f $CONTAINER_NAME
  else
    echo "[!] Node container is not running or not found."
  fi
}

# Function: Delete node and clean up
function delete_all() {
  echo "[!] Removing all related data and containers..."
  docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
  docker volume prune -f >/dev/null 2>&1 || true
  docker network prune -f >/dev/null 2>&1 || true
  docker rmi $IMAGE_NAME >/dev/null 2>&1 || true
  rm -rf "$WORKDIR"
  echo "[✔] Cleanup completed successfully."
}

# Interactive Menu
while true; do
  echo "============================="
  echo " Datagram Node Management Menu"
  echo "============================="
  echo "1. Deploy Node"
  echo "2. View Logs"
  echo "3. Delete Node"
  echo "4. Exit"
  read -p "Enter your choice: " choice

  case "$choice" in
    1) deploy_node ;;
    2) show_logs ;;
    3) delete_all ;;
    4) exit 0 ;;
    *) echo "Invalid option. Please try again." ;;
  esac
done
