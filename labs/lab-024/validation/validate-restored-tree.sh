#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms the ACLs were restored from the backup and temp-vendor was removed.
set -u

T=/srv/data/ledger

acl() { getfacl -p "$1" 2>/dev/null; }

if acl "$T/2025/q1.csv" | grep -q '^user:temp-vendor'; then
  echo "FAIL: temp-vendor still has an entry on $T/2025/q1.csv"
  exit 1
fi

if getfacl -R -p "$T" 2>/dev/null | grep -q 'temp-vendor'; then
  echo "FAIL: temp-vendor still appears in the ACL of the tree (including default entries)"
  exit 1
fi

for d in "$T" "$T/2024" "$T/2025" "$T/tools"; do
  if ! acl "$d" | grep -q '^user:auditor-ivy:r-x'; then
    echo "FAIL: auditor-ivy does not have r-x on $d"
    exit 1
  fi
  if ! acl "$d" | grep -q '^default:user:auditor-ivy:r-x'; then
    echo "FAIL: the default entry for auditor-ivy is missing on $d"
    exit 1
  fi
done

if ! acl "$T/tools/run-report.sh" | grep -q '^user:auditor-ivy:r-x'; then
  echo "FAIL: auditor-ivy does not have r-x on the script"
  exit 1
fi

for f in "$T/summary.txt" "$T/2024/summary.txt" "$T/2025/q2.csv"; do
  if ! acl "$f" | grep -q '^user:auditor-ivy:r--'; then
    echo "FAIL: auditor-ivy does not have r-- on $f"
    exit 1
  fi
done

if ! acl "$T/2025/q1.csv" | grep -q '^user:ledger-clerk:rw-'; then
  echo "FAIL: the entry for ledger-clerk on 2025/q1.csv was not restored"
  exit 1
fi

for p in "$T" "$T/2025/q1.csv"; do
  if [ "$(stat -c %U "$p")" != "ledger-owner" ]; then
    echo "FAIL: the owner of $p changed"
    exit 1
  fi
done

echo "PASS: ACLs restored, temp-vendor removed, owners unchanged"
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
