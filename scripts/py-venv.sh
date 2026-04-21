#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <project_directory>"
    exit 1
fi

project_dir="$1"

if [ ! -d "$project_dir" ]; then
    echo "Error: Project directory not found."
    exit 1
fi


venv_name=$(basename "$(pwd)")
echo "$venv_name"
cd "$project_dir"
python3 -m venv "./$venv_name-venv"
source "./$venv_name-venv/bin/activate"

echo "
# Activate venv:
# source ./$venv_name-venv/bin/activate
#
# Install any required packages
# Example: pip install package_name
#
# When done, deactivate
# deactivate
"
