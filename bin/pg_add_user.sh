#!/bin/bash
# exit on error
set -o errexit

# Check if a username was provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# Get the parameters from the arguments
USERNAME="$1"

# Read password from stdin
read -s -p "Creating user $USERNAME. Enter password: " -r PASSWORD

# Create the SQL command
SQL="CREATE USER $USERNAME WITH PASSWORD '$PASSWORD' CREATEDB SUPERUSER;"

# Execute the command
DBNAME="postgres"
psql -d "$DBNAME" -c "$SQL" ||
  psql -h localhost -p 5432 -U postgres -d "$DBNAME" -c "$SQL" ||
  sudo -u postgres psql -d "$DBNAME" -c "$SQL"
echo "User $USERNAME has been created."
