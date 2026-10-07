#!/usr/bin/env bash

set -euo pipefail


echo "Installing Java 17"
sudo apt update
sudo apt install -y openjdk-17-jdk


echo "Checking Java installation"
java -version
echo "Java installation completed successfully"

