#!/usr/bin/env bash

set -euo pipefail


echo "Installing required Linux utilities"


sudo apt update

sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    pigz \
    gzip \
    tar \
    tree \
    htop \
    tmux \
    screen \
    nano \
    vim \
    jq


echo "Checking installed utilities"


git --version
curl --version | head -n 1
wget --version | head -n 1
pigz --version
tree --version


echo "Utility installation completed successfully"

