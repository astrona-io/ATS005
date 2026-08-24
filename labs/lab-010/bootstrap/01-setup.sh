#!/usr/bin/env bash
# Prepares every pre-existing account/group the capstone transforms
set -eu

# --- analyst9: stale home/group awaiting relocation ---
if ! id analyst9 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash analyst9
fi
echo "q3-forecast-draft" | sudo tee /home/analyst9/forecast.txt > /dev/null
sudo chown analyst9:analyst9 /home/analyst9/forecast.txt

# --- sudo target script for newhire9 ---
sudo tee /root/rotate-logs.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
echo "log rotation executed as $(whoami)"
EOF
sudo chmod 0700 /root/rotate-logs.sh
sudo chown root:root /root/rotate-logs.sh

# --- legacy-billing group awaiting rename ---
if ! getent group legacy-billing >/dev/null; then
  sudo groupadd -g 7000 legacy-billing
fi
if ! id billingclerk >/dev/null 2>&1; then
  sudo useradd -m -G legacy-billing billingclerk
else
  sudo usermod -aG legacy-billing billingclerk
fi

# --- temp-scratch group awaiting deletion ---
sudo groupadd -f temp-scratch

# --- audit2: active account awaiting lockout ---
if ! id audit2 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash audit2
fi
echo "audit2:temporaryPass1" | sudo chpasswd

# --- shortterm3: active account awaiting expiry ---
if ! id shortterm3 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash shortterm3
fi
echo "shortterm3:temporaryPass1" | sudo chpasswd

# --- leaver5: account with a home dir marker, awaiting removal ---
if ! id leaver5 >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash leaver5
fi
echo "final handoff notes" | sudo tee /home/leaver5/handoff.txt > /dev/null
sudo chown leaver5:leaver5 /home/leaver5/handoff.txt

echo "Ready for local account & group lifecycle capstone."
exit 0
