#!/bin/bash

# The platform determines if the script was successful using the exit code 
# of this script. If the exit code is not 0, the script fails. 
set -euxo pipefail

# Disable bash history for the script
HISTFILE=  # Unset the history file, although postgres does not have a home

# Requirements to obtain secret
PREFIX="foo"
POSTFIX="bar"

# Define backup file location
BACKUP_DIR="/tmp/psql_backup"
BACKUP_FILE="postgres_backup_$(date +%Y-%m-%d-%H-%M-%S-%Z).dump"
BACKUP_TARGET=$BACKUP_DIR"/"$BACKUP_FILE

# Disable debugging
set +x

DATABASE_SECRET="${PREFIX}-db-password-${POSTFIX}"
# Get the secret value from Secrets Manager
PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id $DATABASE_SECRET --query SecretString --output text --region us-east-1 2>/dev/null)

# Run the PostgreSQL backup using pg_dump
PGPASSWORD=$PGPASSWORD pg_dump -U postgres -F c -b -v -f $BACKUP_TARGET postgres 2>/dev/null

# Remove all traces
unset PGPASSWORD

# Copy to S3
S3_BUCKET="${PREFIX}-pg-backup-${POSTFIX}"
S3_TARGET="s3://$S3_BUCKET/$BACKUP_FILE"
aws s3 cp $BACKUP_TARGET $S3_TARGET

# Re-enable debugging if needed
set -x

# Optionally, log success or failure
if [ $? -eq 0 ]; then
    logger "PostgreSQL backup succeeded, saved to $BACKUP_TARGET"
else
    logger "PostgreSQL backup failed"
fi

