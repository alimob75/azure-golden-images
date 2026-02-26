#!/bin/bash
set -e

echo "=== Disabling password expiration policy (Azure Custom Script) ==="

# 1. FORCE update /etc/login.defs - sed replace OR append (robust for Azure/Ubuntu 24.04)
sed -i.bak '/^PASS_MAX_DAYS/c\PASS_MAX_DAYS   -1' /etc/login.defs 2>/dev/null || echo 'PASS_MAX_DAYS   -1' >> /etc/login.defs
sed -i.bak '/^PASS_MIN_DAYS/c\PASS_MIN_DAYS   0' /etc/login.defs 2>/dev/null || echo 'PASS_MIN_DAYS   0' >> /etc/login.defs

echo "Updated /etc/login.defs:"
grep '^PASS_(MAX|MIN)_DAYS' /etc/login.defs || echo "PASS_MAX_DAYS/PASS_MIN_DAYS lines added"

# 2. Reset ALL EXISTING local users (skip system ones, handle failures)
echo "Resetting expiry for local users..."
getent passwd | cut -d: -f1 | grep -E '^[^:]+$' | grep -E -v '(nologin|nobody|sync|daemon|root)' | while read -r user; do
  if id "$user" >/dev/null 2>&1; then
    echo "Resetting $user"
    chage -M -1 -I -1 "$user" 2>/dev/null || echo "  -> Skipped $user (no aging data)"
  fi
done

# Verify key user (ansible)
if id ansible >/dev/null 2>&1; then
  echo "Verification - ansible expiry:"
  chage -l ansible | grep "Password expires"
else
  echo "ansible user not found (OK if created later)"
fi

echo "=== SUCCESS: Password expiry disabled for golden image ==="

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
