#!/usr/bin/env bash

set -euo pipefail


echo "Checking Java"
java -version


echo "Installing Nextflow"

cd /tmp

curl -s https://get.nextflow.io | bash

sudo mv nextflow /usr/local/bin/nextflow

sudo chmod +x /usr/local/bin/nextflow


echo "Checking Nextflow installation"
nextflow -version
echo "Nextflow installation completed"

