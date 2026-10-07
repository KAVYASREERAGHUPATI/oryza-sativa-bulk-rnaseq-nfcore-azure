#!/usr/bin/env bash


echo "Preparing Azure 3 TB managed data disk"

# This script does not create or attach a new Azure disk.
# It uses the managed data disk already selected during VM creation.

MOUNT_POINT="/data"
PROJECT_DIR="${MOUNT_POINT}/RNAseq_Project"

# Expected disk size.
# Azure/Linux may report a 3 TB disk as approximately 2.7T or 3T.
MINIMUM_SIZE_BYTES=2500000000000

echo
echo "Current disk information:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS


# Check whether /data is already correctly mounted

if mountpoint -q "$MOUNT_POINT"; then

    echo
    echo "$MOUNT_POINT is already mounted."

    DATA_SOURCE=$(findmnt -n -o SOURCE "$MOUNT_POINT")
    ROOT_SOURCE=$(findmnt -n -o SOURCE /)

    echo "Data source: $DATA_SOURCE"
    echo "Root source: $ROOT_SOURCE"

    if [ "$DATA_SOURCE" = "$ROOT_SOURCE" ]; then
        echo
        echo "ERROR: /data is located on the OS filesystem."
        echo "The RNA-seq project will not be created there."
        exit 1
    fi

else

    echo
    echo "$MOUNT_POINT is not currently mounted."
    echo "Searching for the attached Azure 3 TB managed disk..."

   
    # Detect large non-OS disks

    ROOT_DEVICE=$(findmnt -n -o SOURCE /)

    ROOT_PARENT=$(lsblk -no PKNAME "$ROOT_DEVICE" 2>/dev/null)

    if [ -n "$ROOT_PARENT" ]; then
        OS_DISK="/dev/$ROOT_PARENT"
    else
        OS_DISK="$ROOT_DEVICE"
    fi

    echo "Detected OS disk: $OS_DISK"

    DATA_DISK=""

    while read -r NAME SIZE TYPE
    do
        DEVICE="/dev/$NAME"

        [ "$TYPE" = "disk" ] || continue
        [ "$DEVICE" = "$OS_DISK" ] && continue

        # Skip Azure temporary/resource disk.
        if readlink -f /dev/disk/azure/resource 2>/dev/null |
            grep -q "$(basename "$DEVICE")"
        then
            continue
        fi

        # Select a disk approximately 3 TB or larger than 2.5 TB.
        if [ "$SIZE" -ge "$MINIMUM_SIZE_BYTES" ]; then
            DATA_DISK="$DEVICE"
            break
        fi

    done < <(lsblk -bdn -o NAME,SIZE,TYPE)

    if [ -z "$DATA_DISK" ]; then
        echo
        echo "ERROR: No attached disk of approximately 3 TB was found."
        echo
        echo "Confirm in Azure Portal:"
        echo "Virtual machine > Disks > Data disks"
        echo
        echo "Then check again with:"
        echo "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS"
        exit 1
    fi

    echo
    echo "Detected Azure data disk: $DATA_DISK"
    echo "Disk size: $(lsblk -dn -o SIZE "$DATA_DISK")"

  
    # Detect existing partition

    DATA_PARTITION=$(
        lsblk -nr -o PATH,TYPE "$DATA_DISK" |
        awk '$2 == "part" {print $1}' |
        head -n 1
    )

    if [ -z "$DATA_PARTITION" ]; then

        echo
        echo "The attached data disk has no partition."
        echo "Creating a GPT partition on the new data disk..."

        if ! command -v parted >/dev/null 2>&1; then
            sudo apt update
            sudo apt install -y parted
        fi

        sudo parted -s "$DATA_DISK" mklabel gpt
        sudo parted -s "$DATA_DISK" mkpart primary ext4 0% 100%

        sudo partprobe "$DATA_DISK"
        sleep 3

        DATA_PARTITION=$(
            lsblk -nr -o PATH,TYPE "$DATA_DISK" |
            awk '$2 == "part" {print $1}' |
            head -n 1
        )

        if [ -z "$DATA_PARTITION" ]; then
            echo "ERROR: Partition creation failed."
            exit 1
        fi

        echo "Created partition: $DATA_PARTITION"

    else
        echo
        echo "Existing partition detected: $DATA_PARTITION"
    fi

    # --------------------------------------------------
    # Check filesystem
    # --------------------------------------------------

    FILESYSTEM=$(sudo blkid -s TYPE -o value "$DATA_PARTITION")

    if [ -z "$FILESYSTEM" ]; then

        echo
        echo "No filesystem exists on the new data partition."
        echo "Formatting it as ext4..."

        sudo mkfs.ext4 -F "$DATA_PARTITION"

        FILESYSTEM="ext4"

    else

        echo
        echo "Existing filesystem detected: $FILESYSTEM"
        echo "The disk will not be formatted."

    fi

    if [ "$FILESYSTEM" != "ext4" ] && [ "$FILESYSTEM" != "xfs" ]; then
        echo
        echo "ERROR: Unsupported filesystem: $FILESYSTEM"
        echo "Review the disk manually before continuing."
        exit 1
    fi

    # --------------------------------------------------
    # Obtain UUID
    # --------------------------------------------------

    UUID=$(sudo blkid -s UUID -o value "$DATA_PARTITION")

    if [ -z "$UUID" ]; then
        echo "ERROR: Unable to obtain the disk UUID."
        exit 1
    fi

    echo "Filesystem UUID: $UUID"

    # --------------------------------------------------
    # Create mount point
    # --------------------------------------------------

    sudo mkdir -p "$MOUNT_POINT"

    # --------------------------------------------------
    # Configure automatic mounting
    # --------------------------------------------------

    FSTAB_ENTRY="UUID=${UUID} ${MOUNT_POINT} ${FILESYSTEM} defaults,nofail 0 2"

    if grep -qE "^[^#].+[[:space:]]${MOUNT_POINT}[[:space:]]" /etc/fstab; then

        echo
        echo "An /etc/fstab entry for $MOUNT_POINT already exists."
        echo "The existing entry will not be changed."

    else

        echo
        echo "Backing up /etc/fstab..."

        sudo cp /etc/fstab \
            "/etc/fstab.backup.$(date +%Y%m%d_%H%M%S)"

        echo "Adding persistent data-disk mount..."

        echo "$FSTAB_ENTRY" |
            sudo tee -a /etc/fstab > /dev/null

    fi

    # --------------------------------------------------
    # Mount and verify
    # --------------------------------------------------

    echo
    echo "Mounting the Azure data disk..."

    sudo mount -a

    if ! mountpoint -q "$MOUNT_POINT"; then
        echo
        echo "ERROR: The Azure data disk was not mounted."
        exit 1
    fi

fi


# Verify that /data is not the OS or temporary disk

DATA_SOURCE=$(findmnt -n -o SOURCE "$MOUNT_POINT")
ROOT_SOURCE=$(findmnt -n -o SOURCE /)

RESOURCE_DEVICE=$(readlink -f /dev/disk/azure/resource 2>/dev/null || true)
DATA_DEVICE=$(readlink -f "$DATA_SOURCE" 2>/dev/null || echo "$DATA_SOURCE")

echo
echo "Final storage verification:"
echo "OS filesystem:       $ROOT_SOURCE"
echo "Project filesystem:  $DATA_SOURCE"
echo "Azure resource disk: ${RESOURCE_DEVICE:-Not detected}"

if [ "$DATA_SOURCE" = "$ROOT_SOURCE" ]; then
    echo
    echo "ERROR: /data is still using the OS disk."
    exit 1
fi

if [ -n "$RESOURCE_DEVICE" ] &&
   [[ "$DATA_DEVICE" == "$RESOURCE_DEVICE"* ]]; then
    echo
    echo "ERROR: /data points to Azure temporary storage."
    echo "Temporary storage must not be used for this project."
    exit 1
fi

# Create project directories

echo
echo "Creating RNA-seq project directories..."

sudo mkdir -p \
    "${PROJECT_DIR}/fastq" \
    "${PROJECT_DIR}/reference" \
    "${PROJECT_DIR}/metadata" \
    "${PROJECT_DIR}/results" \
    "${PROJECT_DIR}/work" \
    "${PROJECT_DIR}/tmp" \
    "${PROJECT_DIR}/logs" \
    "${PROJECT_DIR}/sra_cache" \
    "${PROJECT_DIR}/scripts" \
    "${PROJECT_DIR}/config"

sudo chown -R "$USER":"$USER" "$PROJECT_DIR"


# Test data-disk write access

TEST_FILE="${PROJECT_DIR}/.write_test"

touch "$TEST_FILE"

if [ ! -f "$TEST_FILE" ]; then
    echo
    echo "ERROR: Unable to write to the project directory."
    exit 1
fi

rm -f "$TEST_FILE"


# Final output

echo
echo "Azure data disk preparation completed"
echo
echo "Mounted disk:"
findmnt "$MOUNT_POINT"

echo
echo "Available space:"
df -h "$MOUNT_POINT"

echo
echo "Project directory:"
echo "$PROJECT_DIR"

echo
echo "Nextflow work directory:"
echo "${PROJECT_DIR}/work"

echo
echo "Temporary directory:"
echo "${PROJECT_DIR}/tmp"

echo
echo "All RNA-seq files must be stored under:"
echo "$PROJECT_DIR"
