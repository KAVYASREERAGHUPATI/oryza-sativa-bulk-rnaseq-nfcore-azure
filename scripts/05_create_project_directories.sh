#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="/data/RNAseq_Project"


echo "Creating RNA-seq project directories"


# Check if the Azure data disk is mounted
if ! mountpoint -q /data; then
    echo "ERROR: The Azure data disk is not mounted at /data."
    echo "Please run 00_prepare_data_disk.sh first."
    exit 1
fi

sudo mkdir -p "${PROJECT_DIR}"
sudo chown "$USER":"$USER" "${PROJECT_DIR}"

mkdir -p "${PROJECT_DIR}/fastq"
mkdir -p "${PROJECT_DIR}/reference"
mkdir -p "${PROJECT_DIR}/metadata"
mkdir -p "${PROJECT_DIR}/scripts"
mkdir -p "${PROJECT_DIR}/results"
mkdir -p "${PROJECT_DIR}/work"
mkdir -p "${PROJECT_DIR}/logs"
mkdir -p "${PROJECT_DIR}/tmp"
mkdir -p "${PROJECT_DIR}/downloads"
mkdir -p "${PROJECT_DIR}/config"
mkdir -p "${PROJECT_DIR}/sra_cache"


echo "Project directory structure"

tree "${PROJECT_DIR}"

echo "=========================================="
echo "Directories created successfully"
echo "=========================================="
