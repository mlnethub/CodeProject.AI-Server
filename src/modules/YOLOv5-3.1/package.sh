#!/bin/bash

# Module Packaging script. To be called from create_packages.sh

moduleId=$1
version=$2

tar -caf ${moduleId}-${version}.zip --exclude=__pycache__  --exclude=*.development.* --exclude=*.log \
    commons/* models/* recognition/* utils/* *.py modulesettings.* requirements.* install.sh install.bat
