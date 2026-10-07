#!/usr/bin/env bash


echo "Checking Docker installation..."


if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed."
    docker --version
else
    echo "Docker is not installed."
    echo "Installing Docker..."

    sudo apt update
    sudo apt install -y docker.io

    echo "Starting and enabling Docker service..."
    sudo systemctl enable --now docker

    echo "Adding current user to Docker group..."
    sudo usermod -aG docker "$USER"

    echo "Refreshing Docker group membership..."
    newgrp docker
fi


echo "Verifying Docker installation..."
docker --version
docker run --rm hello-world


echo "Listing running Docker containers..."
docker ps


echo "Installing bioinformatics tools..."

sudo apt update
sudo apt install -y \
    sra-toolkit \
    pigz \
    parallel




