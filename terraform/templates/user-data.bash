#!/usr/bin/bash
# The platform determines if the script was successful using the exit code 
# of this script. If the exit code is not 0, the script fails. 
set -euxo pipefail

# Ensure we are able to install packages.
export DEBIAN_FRONTEND=noninteractive
UCF_FORCE_CONFFOLD=true apt upgrade -y
apt update -y
apt-get update -qq -y

# Function to check if a package is installed
check_and_install() {
    PACKAGE=$1
    if ! dpkg -l | grep -q "$PACKAGE"; then
        logger $(date)" $PACKAGE is not installed. Installing..."
        sudo apt update
        sudo apt install -y "$PACKAGE"
        
        # Check if installation was successful
        if [ $? -eq 0 ]; then
            logger $(date)" $PACKAGE installed successfully."
        else
            logger $(date)" Failed to install $PACKAGE. Exiting."
            exit 1
        fi
    else
        logger $(date)" $PACKAGE is already installed."
    fi
}

# Loop through the packages and ensure each is installed
for PACKAGE in "awscli" "postgresql" "postgresql-client" "jq"; do
    check_and_install "$PACKAGE"
done

# Check if the previous command was successful
if [ $? -eq 0 ]; then
  logger $(date)" All packages installed successfully."
else
  logger $(date)" Package installation failed. Exiting."
  exit 1
fi

logger $(date)" Proceeding with the rest of the script..."

# Configure PostgreSQL

# Extract the version number from /etc/postgresql directory
PGVERSION=$(ls /etc/postgresql | grep -E '^[0-9]+$')

# Allow all available IP interfaces (IPv4 and IPv6)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$PGVERSION/main/postgresql.conf

# Requirements to obtain secret
DATABASE_SECRET="${PREFIX}-db-password-${POSTFIX}"

# Get the secret value from Secrets Manager
PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id $DATABASE_SECRET --query SecretString --output text --region us-east-1)

# Use fragments to unsplat the initial pg command
fg1="ALTER USER postgres with encrypted password '"
fg2=$PGPASSWORD
fg3="';"
PGCOMMAND=$fg1$fg2$fg3

sudo -u postgres psql -d postgres -c "$PGCOMMAND"

# Enable scram-sha-256 authentication from the local network only
CIDR=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
sudo echo "" >>  /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo echo "# Allow scram-sha-256 authentication with the postgres user" >>  /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo echo "hostssl    postgres       postgres        $CIDR        md5" >> /etc/postgresql/$PGVERSION/main/pg_hba.conf

# Restart PostgreSQL:
sudo systemctl restart postgresql.service
sudo systemctl enable postgresql

# Create main table
sudo -u postgres PGPASSWORD=$PGPASSWORD psql -c "CREATE TABLE robot_records (id SERIAL PRIMARY KEY, filename UUID, bot_name VARCHAR(255), bot_story TEXT);"

# Create database
DATABASE_FILE="/home/ubuntu/db-data/character_payload.json"

jq -c '.[]' "$DATABASE_FILE" | while read -r record; do
  # Extract fields using jq
  IMAGENAME=$(echo "$record" | jq -r '.filename')
  BOTNAME=$(echo "$record" | jq -r '.bot_name')
  BOTSTORY=$(echo "$record" | jq -r '.bot_story')

  # Insert the record into PostgreSQL
  sudo -u postgres PGPASSWORD=$PGPASSWORD psql -c "INSERT INTO robot_records (filename, bot_name, bot_story) VALUES ('$IMAGENAME', '$BOTNAME', '$BOTSTORY');"

  # Check if the insert was successful
  if [ $? -eq 0 ]; then
    echo "Inserted record for $BOTNAME with filename $IMAGENAME"
  else
    echo "Failed to insert record for $BOTNAME with filename $IMAGENAME"
  fi
done

sudo -u postgres PGPASSWORD=$PGPASSWORD psql -c "select * from robot_records;"

# Basic clean up for user ubuntu
rm -fR /home/ubuntu/db-data

# Testing settings:

# Define PostgreSQL connection details
PGHOST=$(hostname)
PGPORT="5432"
PGUSER="postgres"
PGDATABASE="postgres"

# Create an output location and file
OUTPUT_DIR="/tmp/psql"
sudo mkdir $OUTPUT_DIR
sudo chmod 755 $OUTPUT_DIR
sudo chown postgres:postgres $OUTPUT_DIR
OUTPUT_FILE="psql_connect.log"
OUTPUT_TARGET=$OUTPUT_DIR"/"$OUTPUT_FILE

sudo -u postgres PGPASSWORD=$PGPASSWORD psql "postgresql://$PGUSER@$PGHOST:$PGPORT/$PGDATABASE" -c "\conninfo" > $OUTPUT_TARGET 2>&1 

# Create first backup for testing
# Create an backup location and file
BACKUP_DIR="/tmp/psql_backup"
sudo mkdir $BACKUP_DIR
sudo chmod 755 $BACKUP_DIR
sudo chown postgres:postgres $BACKUP_DIR
BACKUP_FILE="postgres_backup_$(date +%Y-%m-%d-%H-%M-%S-%Z).dump"
BACKUP_TARGET=$BACKUP_DIR"/"$BACKUP_FILE

# Use the db dump backup method
PGPASSWORD=$PGPASSWORD sudo -u postgres pg_dump -U postgres -F c -b -v -f $BACKUP_TARGET postgres

# Copy to S3
S3_BUCKET="${PREFIX}-pg-backup-${POSTFIX}"
S3_TARGET="s3://$S3_BUCKET/$BACKUP_FILE"
aws s3 cp $BACKUP_TARGET $S3_TARGET

# Setup custom backup-service
PAYLOAD_DIR="/home/ubuntu/postgres-backup"

# Loop until the directory exists
while [ ! -d "$PAYLOAD_DIR" ]; do
  echo "Waiting for directory $DIR to be created..."
  sleep 5  # Wait for 5 seconds before checking again
done

# We should be working with the following structure:
# /home/ubuntu/postgres-backup/
# ├── postgres_backup.bash
# ├── postgres-backup.service
# └── postgres-backup.timer

BACKUP_SCRIPT=$PAYLOAD_DIR"/postgres_backup.bash"
BACKUP_SERVICE=$PAYLOAD_DIR"/postgres-backup.service"
BACKUP_TIMER=$PAYLOAD_DIR"/postgres-backup.timer"

sudo sed -i "s/^PREFIX=\".*\"/PREFIX=\"${PREFIX}\"/" $BACKUP_SCRIPT
sudo sed -i "s/^POSTFIX=\".*\"/POSTFIX=\"${POSTFIX}\"/" $BACKUP_SCRIPT

sudo chmod +x $BACKUP_SCRIPT
sudo chown postgres:postgres $BACKUP_SCRIPT
sudo mv $BACKUP_SCRIPT /usr/local/bin/.

sudo chmod +x $BACKUP_SERVICE
sudo chown root:root $BACKUP_SERVICE
sudo mv $BACKUP_SERVICE /etc/systemd/system/.

sudo chmod +x $BACKUP_TIMER
sudo chown root:root $BACKUP_TIMER
sudo mv $BACKUP_TIMER /etc/systemd/system/.

sudo systemctl daemon-reload
sudo systemctl enable postgres-backup.timer
sudo systemctl start postgres-backup.timer

sudo systemctl enable postgres-backup.service
sudo systemctl start postgres-backup.service

sudo rm -fR $PAYLOAD_DIR
