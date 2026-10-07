#!/usr/bin/env bash

set -euo pipefail

echo "Downloading SRA samples and creating FASTQ files"

# Check whether the data disk is mounted
if ! mountpoint -q /data; then
    echo "ERROR: The data disk is not mounted at /data."
    echo "Please run 00_prepare_data_disk.sh first."
    exit 1
fi

PROJECT_DIR="/data/RNAseq_Project"
ACCESSION_FILE="${PROJECT_DIR}/metadata/sra_accessions.txt"
FASTQ_DIR="${PROJECT_DIR}/fastq"
SRA_CACHE_DIR="${PROJECT_DIR}/sra_cache"
TMP_DIR="${PROJECT_DIR}/tmp"

mkdir -p "${FASTQ_DIR}"
mkdir -p "${SRA_CACHE_DIR}"
mkdir -p "${TMP_DIR}"

cd "${FASTQ_DIR}"

while IFS= read -r SRR
do
    SRR=$(echo "${SRR}" | tr -d '\r')

    if [[ -z "${SRR}" ]]; then
        continue
    fi

   
    echo "Downloading ${SRR}"

    prefetch "${SRR}" \
        --output-directory "${SRA_CACHE_DIR}" \
        --max-size u

    echo "Converting ${SRR} to paired-end FASTQ files"

    fasterq-dump "${SRA_CACHE_DIR}/${SRR}/${SRR}.sra" \
        --split-files \
        --threads 8 \
        --temp "${TMP_DIR}" \
        --outdir "${FASTQ_DIR}"

    echo "Compressing ${SRR} FASTQ files"

    pigz -p 8 "${FASTQ_DIR}/${SRR}_1.fastq"
    pigz -p 8 "${FASTQ_DIR}/${SRR}_2.fastq"

    echo "${SRR} completed"

done < "${ACCESSION_FILE}"

echo "All accessions downloaded successfully
echo "FASTQ files are available in:"
echo "${FASTQ_DIR}"
