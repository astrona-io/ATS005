#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
sudo -n bash <<'BOOTSTRAP_ROOT'
# Starting state for lab-024: a ledger tree with many ACL entries and a
# cleanup script that strips them all. The backup and restore are the task.
set -eu

apt-get install -y acl >/dev/null 2>&1 || true

for u in ledger-owner auditor-ivy temp-vendor ledger-clerk; do
  id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
done

rm -rf /srv/data/ledger
mkdir -p /srv/data/ledger/2024 /srv/data/ledger/2025 /srv/data/ledger/tools
echo "totals 2024" > /srv/data/ledger/2024/summary.txt
echo "id,amount" > /srv/data/ledger/2025/q1.csv
echo "id,amount" > /srv/data/ledger/2025/q2.csv
echo "totals" > /srv/data/ledger/summary.txt
printf '#!/bin/sh\necho report\n' > /srv/data/ledger/tools/run-report.sh
chmod 750 /srv/data/ledger/tools/run-report.sh
chown -R ledger-owner:ledger-owner /srv/data/ledger
chmod 750 /srv/data/ledger /srv/data/ledger/2024 /srv/data/ledger/2025 /srv/data/ledger/tools

setfacl -R -m u:auditor-ivy:rX /srv/data/ledger
setfacl -R -m u:temp-vendor:rX /srv/data/ledger
find /srv/data/ledger -type d -exec setfacl -d -m u:auditor-ivy:rx {} +
setfacl -m u:ledger-clerk:rw /srv/data/ledger/2025/q1.csv

cat > /root/strip-acls.sh <<'SCRIPT'
#!/bin/sh
setfacl -R -b /srv/data/ledger
SCRIPT
chmod 755 /root/strip-acls.sh

exit 0
BOOTSTRAP_ROOT
ASTRONA_STUDENT_SCRIPT
