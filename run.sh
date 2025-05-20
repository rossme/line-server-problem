#!/bin/bash

# Make both scripts executable with `chmod +x build.sh run.sh`
# Exit immediately if a command exits with a non-zero status
set -o errexit

# Example `./run.sh "<path_to_your_ascii_txt_file>"`

if [ -z "$1" ]; then
  echo "Usage: ./run.sh <filename>"
  exit 1
fi

filename="$1"

if [ ! -f "$filename" ]; then
  echo "Error: File '$filename' not found."
  exit 1
fi

# Set the environment variable
export FILE_TO_PREPROCESS="$filename"

echo "Starting Rails 8 server with file: $FILE_TO_PREPROCESS..."
bundle exec bin/dev

echo "Preprocessing file $FILE_TO_PREPROCESS... Please wait."
