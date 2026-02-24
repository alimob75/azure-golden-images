#!/bin/bash
set -e

echo "Preparing Linux VM for generalization..."

sudo shutdown +3
sudo waagent -deprovision+user -verbose -force -start

sleep 60
# Stop services
sudo systemctl stop ssh || true
sudo systemctl stop sshd || true
sudo systemctl stop cloud-init || true
sudo systemctl stop cloud-init-local || true
sudo systemctl stop cloud-init-config || true
sudo systemctl stop cloud-init-final || true


# CLOUD-INIT CLEANUP (CRITICAL)
sudo cloud-init clean --logs || true
sudo cloud-init clean || true
sudo rm -rf /var/lib/cloud/instances/* /var/lib/cloud/sem/ || true

# SSH keys (prevent regeneration)
sudo rm -f /etc/ssh/ssh_host_*
