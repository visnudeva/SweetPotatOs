#!/usr/bin/bash
# Drop stale lid-ignore drop-in; ensure SweetPotatOs lid-sleep policy wins.
set -euo pipefail

stale=/etc/systemd/logind.conf.d/do-not-suspend.conf
if [[ -f "${stale}" ]]; then
  echo "[migration 001] Removing ${stale}"
  rm -f "${stale}"
fi

if [[ -f /etc/systemd/logind.conf.d/lid-sleep.conf ]] \
  && [[ ! -f /etc/systemd/logind.conf.d/50-sweetpotatos-lid-sleep.conf ]]; then
  echo "[migration 001] Renaming lid-sleep.conf → 50-sweetpotatos-lid-sleep.conf"
  mv /etc/systemd/logind.conf.d/lid-sleep.conf \
    /etc/systemd/logind.conf.d/50-sweetpotatos-lid-sleep.conf
fi

if systemctl is-active systemd-logind &>/dev/null; then
  systemctl restart systemd-logind || true
fi
