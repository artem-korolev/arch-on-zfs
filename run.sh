#!/bin/bash

# Install dependencies
pip install --user -r requirements.txt

# Run all necessary parts of the codebase
ansible-playbook playbooks/main.yml



