#!/bin/bash
# exit on error
set -o errexit

# Check if a username was provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# Get the username from the first argument
USERNAME="$1"

# Read password from stdin
read -r PASSWORD

# Create the SQL command
SQL="CREATE USER $USERNAME WITH PASSWORD '$PASSWORD' CREATEDB;"

# Execute the command
sudo -u postgres psql -d "$DBNAME" -c "$SQL"

echo "User $USERNAME has been created."
