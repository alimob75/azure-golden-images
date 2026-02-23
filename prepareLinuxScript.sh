#!/bin/bash
set -e

echo "Preparing Linux VM for generalization..."

sudo shutdown +5
sudo waagent -deprovision+user -verbose -force -start
