#!/usr/bin/env bash

set -euo pipefail


echo "Running nf-core/rnaseq pipeline"


# Check whether the data disk is mounted

if ! mountpoint -q /data; then
    echo "ERROR: The data disk is not mounted at /data."
    echo "Please run 00_prepare_data_disk.sh first."
    exit 1
fi


# Define project directories

PROJECT_DIR="/data/RNAseq_Project"

SAMPLESHEET="${PROJECT_DIR}/metadata/samplesheet.csv"

REFERENCE_DIR="${PROJECT_DIR}/reference"

RESULTS_DIR="${PROJECT_DIR}/results"

CONFIG_FILE="config/nextflow.config"


# Run nf-core/rnaseq

nextflow run nf-core/rnaseq \
    -profile docker \
    -c "${CONFIG_FILE}" \
    --input "${SAMPLESHEET}" \
    --outdir "${RESULTS_DIR}" \
    --fasta "${REFERENCE_DIR}/Oryza_sativa.IRGSP-1.0.dna_sm.toplevel.fa.gz" \
    --gtf "${REFERENCE_DIR}/Oryza_sativa.IRGSP-1.0.62.gtf.gz" \
    --aligner star_salmon \
    -resume


echo "RNA-seq pipeline completed successfully"

echo "Results directory:"
echo "${RESULTS_DIR}"
