#!/bin/bash
set -e

echo "=== Disabling password expiration policy ==="

# 1. Update /etc/login.defs for ALL NEW users (prevents future expiries)
sed -i 's/^PASS_MAX_DAYS\s\+[0-9]\+$/PASS_MAX_DAYS   -1/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS\s\+[0-9]\+$/PASS_MIN_DAYS   0/' /etc/login.defs

# Ensure they're set even if no existing line
grep -q '^PASS_MAX_DAYS' /etc/login.defs || echo 'PASS_MAX_DAYS   -1' >> /etc/login.defs
grep -q '^PASS_MIN_DAYS' /etc/login.defs || echo 'PASS_MIN_DAYS   0' >> /etc/login.defs

echo "Updated /etc/login.defs:"
grep '^PASS_(MAX|MIN)_DAYS' /etc/login.defs

# 2. Reset ALL EXISTING local users (one-time for image)
echo "Resetting expiry for all local users..."
getent passwd | cut -d: -f1 | grep -E -v '(nologin|nobody|sync)' | while read -r user; do
  echo "Resetting $user"
  chage -M -1 -I -1 "$user" 2>/dev/null || true
done

echo "=== Done. New VMs will have non-expiring accounts. ==="

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
