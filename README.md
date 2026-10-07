# oryza-sativa-bulk-rnaseq-nfcore-azure
End-to-end bulk RNA-seq analysis of Oryza sativa under drought stress using nf-core/rnaseq, Nextflow and Microsoft Azure.
This repository contains the complete workflow used for bulk RNA sequencing (RNA-seq) analysis of Oryza sativa (rice) under drought stress using the nf-core/rnaseq pipeline executed with Nextflow on Microsoft Azure. The project includes Azure virtual machine specifications, input files, execution commands, and downstream analyses.
............................................................................................................
## Dataset Description

GEO ID:	GSE288615
Bioproject ID:	PRJNA1218689
Source:	IR64 (Oryza sativa Indica Group)
Project URL:	https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1218689
Library layout:	PAIRED
Platform/Encoding:	Illumina NovaSeq 6000
Library selection:	cDNA
Strategy:	RNA Seq
............................................................................................................
## Project Details

Organism: Oryza sativa (Rice)
Variety: IR64
Data Source: NCBI SRA (BioProject: PRJNA1218689)
Experimental Conditions: Control vs  Drought
Samples Processed: 35 (18 Control, 17 Drought)
Pipeline: nf-core/rnaseq
Workflow Manager: Nextflow
Cloud Platform: Microsoft Azure

............................................................................................................
## Microsoft Azure Virtual Machine Specifications
 
Cloud Platform:	Microsoft Azure
Virtual Machine Type:	Standard_FX32-16ms_v2
Processor:	16 vCPUs
Memory (RAM):	672 GiB
Operating System Disk:	256 GB
Data Storage Disk:	3 TB
instance: spot instance (#cheeper in cost)
Operating System: Ubuntu Server 24.04 LTS (64-bit)

**Important:** Azure Spot virtual machines can be interrupted or evicted when Azure requires the computing capacity. Therefore, Nextflow resume functionality and regular backup of important files are recommended.

............................................................................................................
The analysis was executed in a Linux environment on Microsoft Azure. PuTTY was used to establish the SSH connection between the local Windows computer and the Azure virtual mechine

Software Category and 	Tool/Version:-
SSH Client:	PuTTY
............................................................................................................
## General Workflow

The following steps were followed to prepare and execute the RNA-seq analysis:

1. A Microsoft Azure Spot virtual machine was created with the required CPU, memory and storage capacity (mentioned above).
2. Ubuntu Server 24.04 LTS was selected as the operating system.
3. PuTTY was used to connect to the Azure virtual machine through SSH.
4. Nextflow and the nf-core/rnaseq pipeline were installed on the Linux virtual machine (VM).
5. The *Oryza sativa* reference genome and GTF annotation files were downloaded to VM using the code.
7. Publicly available RNA-seq sample files were downloaded directly to the Azure virtual machine from NCBI SRA or EMBL-EBI using command-line tools.
8. A sample sheet containing the sample names and paired-end FASTQ file paths was prepared.
9. The nf-core/rnaseq pipeline was executed using Nextflow.
10. Pipeline outputs were examined using MultiQC and used for downstream analyses.
    
............................................................................................................
## File Transfer Using WinSCP

the output files were downloaded from linux VM to local computer usinfg winSCP
............................................................................................................
## nf-core/rnaseq Pipeline Workflow

Raw paired-end FASTQ files (downloaded from NCBI using code, directly to linux)
        ↓
     FASTQC
Evaluates the quality of the raw sequencing reads.
        ↓
      STAR
Aligns the sequencing reads to the reference genome.
        ↓
     SALMON
Quantifies transcript expression levels.
        ↓
   FEATURECOUNTS
Counts the reads assigned to each annotated gene.
        ↓
     MULTIQC
Combines quality-control and pipeline reports into a single summary report.
..................................................................................................................
## Configuration and Storage

The `nextflow.config` file can be modified according to the CPU, memory, and other resource specifications of the selected Azure virtual machine.

The attached data disk, mounted at `/data`, is used to store all RNA-seq project files. These include:

- FASTQ files
- Reference genome and annotation files
- SRA downloads
- Temporary files
- Nextflow work files
- Pipeline results
- Log files

The scripts in the `scripts/` directory are configured to store these files under:

/data/RNAseq_Project
So, this prevents large RNA-seq files from being written to the operating system disk.
