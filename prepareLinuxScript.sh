#!/bin/bash
set -e

echo "Preparing Linux VM for generalization..."

sudo shutdown +3
sudo waagent -deprovision+user -verbose -force -start

sleep 60
# Stop services
sudo systemctl stop ssh sshd cloud-init cloud-init-local cloud-init-config cloud-init-final

# CLOUD-INIT CLEANUP (CRITICAL)
sudo cloud-init clean --logs
sudo cloud-init clean
sudo rm -rf /var/lib/cloud/instances/* /var/lib/cloud/sem/

# SSH keys (prevent regeneration)
sudo rm -f /etc/ssh/ssh_host_*
