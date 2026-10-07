#!/usr/bin/env bash

set -euo pipefail

echo "Downloading Reference Genome and Annotation"

# Check whether the data disk is mounted

if ! mountpoint -q /data; then
    echo "ERROR: The Azure data disk is not mounted at /data."
    echo "Please run 00_prepare_data_disk.sh first."
    exit 1
fi


# Project directories

PROJECT_DIR="/data/RNAseq_Project"
REFERENCE_DIR="${PROJECT_DIR}/reference"

mkdir -p "${REFERENCE_DIR}"

cd "${REFERENCE_DIR}"

echo
echo "Reference files will be downloaded to:"
pwd


# Reference file names and URLs
FASTA="${REFERENCE_DIR}/Oryza_sativa.IRGSP-1.0.dna_sm.toplevel.fa.gz"
GTF="${REFERENCE_DIR}/Oryza_sativa.IRGSP-1.0.62.gtf.gz"

FASTA_URL="https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-62/fasta/oryza_sativa/dna/Oryza_sativa.IRGSP-1.0.dna_sm.toplevel.fa.gz"
GTF_URL="https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-62/gtf/oryza_sativa/Oryza_sativa.IRGSP-1.0.62.gtf.gz"


# Download reference genome

if [[ -f "${FASTA}" ]]; then
    echo "Reference genome already exists."
    echo "Checking the existing file before skipping download."

    if gzip -t "${FASTA}"; then
        echo "Existing reference genome passed the gzip integrity test."
    else
        echo "Existing reference genome is incomplete or corrupted."
        echo "Removing the damaged file and downloading it again."
        rm -f "${FASTA}"
        wget -c "${FASTA_URL}"
    fi
else
    wget -c "${FASTA_URL}"
fi


# Download GTF annotation

if [[ -f "${GTF}" ]]; then
    echo "GTF annotation already exists."
    echo "Checking the existing file before skipping download."

    if gzip -t "${GTF}"; then
        echo "Existing annotation file passed the gzip integrity test."
    else
        echo "Existing annotation file is incomplete or corrupted."
        echo "Removing the damaged file and downloading it again."
        rm -f "${GTF}"
        wget -c "${GTF_URL}"
    fi
else
    wget -c "${GTF_URL}"
fi


# Check downloaded files
echo "Checking downloaded reference genome"

if [[ ! -s "${FASTA}" ]]; then
    echo "ERROR: Reference genome was not downloaded correctly."
    echo "Expected file:"
    echo "${FASTA}"
    exit 1
fi

echo "Reference genome is available:"
ls -lh "${FASTA}"

echo "Checking downloaded annotation"

if [[ ! -s "${GTF}" ]]; then
    echo "ERROR: Annotation file was not downloaded correctly."
    echo "Expected file:"
    echo "${GTF}"
    exit 1
fi

echo "Annotation file is available:"
ls -lh "${GTF}"

echo "Testing compressed files"

gzip -t "${FASTA}"
echo "Reference genome passed the gzip integrity test."

gzip -t "${GTF}"
echo "Annotation file passed the gzip integrity test."

echo "Reference download completed successfully"
