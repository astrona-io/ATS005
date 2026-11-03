#!/usr/bin/env bash
# Confirms what anna, ben and cleo may run through sudo, and that nobody got ALL.

set -u

STATUS_CMD="/usr/bin/systemctl status ssh"
RESTART_CMD="/usr/bin/systemctl restart ssh"
STOP_CMD="/usr/bin/systemctl stop ssh"
LOG_CMD="/usr/bin/journalctl -u ssh"

# Run "sudo -n -l <command>" as a user. Exit status 0 means sudo allows it
# without a password prompt.
allowed_without_password() {
  local account="$1"
  local command_line="$2"
  su -s /bin/bash -c "sudo -n -l $command_line" "$account" >/dev/null 2>&1
}

for account in anna ben; do
  for command_line in "$STATUS_CMD" "$RESTART_CMD"; do
    if ! allowed_without_password "$account" "$command_line"; then
      echo "FAIL: $account cannot run '$command_line' through sudo without a password"
      exit 1
    fi
  done
  if allowed_without_password "$account" "$STOP_CMD"; then
    echo "FAIL: $account may run '$STOP_CMD', but the rule must stay as narrow as the alias"
    exit 1
  fi
  if allowed_without_password "$account" "$LOG_CMD"; then
    echo "FAIL: $account may run '$LOG_CMD' without a password; only cleo gets that command"
    exit 1
  fi
done

cleo_rules=$(sudo -l -U cleo 2>/dev/null)

if ! echo "$cleo_rules" | grep -qF "$LOG_CMD"; then
  echo "FAIL: sudo -l -U cleo does not list '$LOG_CMD'"
  exit 1
fi

if echo "$cleo_rules" | grep -F "$LOG_CMD" | grep -q 'NOPASSWD'; then
  echo "FAIL: cleo's journalctl rule uses NOPASSWD; she must type her own password"
  exit 1
fi

if allowed_without_password cleo "$RESTART_CMD"; then
  echo "FAIL: cleo may restart ssh without a password; that rule is for webops only"
  exit 1
fi

for account in anna ben cleo; do
  if sudo -l -U "$account" 2>/dev/null | grep -qE '\) +(NOPASSWD: +)?ALL[[:space:]]*$'; then
    echo "FAIL: $account may run ALL commands through sudo"
    exit 1
  fi
done

echo "PASS: webops and cleo have exactly the sudo rules the task asks for"
exit 0
