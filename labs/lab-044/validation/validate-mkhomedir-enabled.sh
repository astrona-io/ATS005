#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms pam_mkhomedir is active in the shared session steps and the
# starter file exists.
set -u

if ! grep -Eq '^session[[:space:]].*pam_mkhomedir\.so' /etc/pam.d/common-session; then
  echo "FAIL: pam_mkhomedir.so is not an active session line in /etc/pam.d/common-session"
  exit 1
fi

if [ ! -f /etc/skel/WELCOME.txt ]; then
  echo "FAIL: /etc/skel/WELCOME.txt does not exist"
  exit 1
fi

if [ ! -s /etc/skel/WELCOME.txt ]; then
  echo "FAIL: /etc/skel/WELCOME.txt is empty"
  exit 1
fi

echo "PASS: pam_mkhomedir is active and /etc/skel/WELCOME.txt exists"
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
