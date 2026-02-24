#!/bin/bash
set -e

echo "Preparing Linux VM for generalization..."

sudo shutdown +3
sudo waagent -deprovision+user -verbose -force -start
