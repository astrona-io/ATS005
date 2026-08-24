#!/usr/bin/env bash
# Confirms billing-team created, legacy-billing renamed to archive-billing, and temp-scratch deleted
set -u

billing_team=$(getent group billing-team 2>/dev/null)
if [[ -z "$billing_team" ]]; then
  echo "FAIL: groups lifecycle - billing-team does not exist"
  exit 1
fi
if [[ "$(cut -d: -f3 <<< "$billing_team")" != "6000" ]]; then
  echo "FAIL: groups lifecycle - billing-team GID is '$(cut -d: -f3 <<< "$billing_team")', expected '6000'"
  exit 1
fi
members=$(cut -d: -f4 <<< "$billing_team")
for u in analyst9 newhire9; do
  if ! grep -qw "$u" <<< "$members"; then
    echo "FAIL: groups lifecycle - billing-team missing member '$u' (members: $members)"
    exit 1
  fi
done

if getent group legacy-billing >/dev/null 2>&1; then
  echo "FAIL: groups lifecycle - legacy-billing still exists; it should have been renamed"
  exit 1
fi
archive_billing=$(getent group archive-billing 2>/dev/null)
if [[ -z "$archive_billing" ]]; then
  echo "FAIL: groups lifecycle - archive-billing does not exist"
  exit 1
fi
if [[ "$(cut -d: -f3 <<< "$archive_billing")" != "7000" ]]; then
  echo "FAIL: groups lifecycle - archive-billing GID is '$(cut -d: -f3 <<< "$archive_billing")', expected '7000' (unchanged from legacy-billing)"
  exit 1
fi
if ! grep -qw "billingclerk" <<< "$(cut -d: -f4 <<< "$archive_billing")"; then
  echo "FAIL: groups lifecycle - archive-billing lost its original member 'billingclerk'"
  exit 1
fi

if getent group temp-scratch >/dev/null 2>&1; then
  echo "FAIL: groups lifecycle - temp-scratch still exists, expected to be deleted"
  exit 1
fi

echo "PASS: billing-team created, legacy-billing renamed to archive-billing intact, temp-scratch deleted."
exit 0
