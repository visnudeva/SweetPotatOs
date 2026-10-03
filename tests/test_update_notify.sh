#!/usr/bin/env bash
# Run the weekly update check and notice with a fake pacman and notify-send.
# Does not touch the host pacman databases or send a real desktop notification.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPD="${ROOT}/packaging/sweetpotatos/sweetpotatos-update"
NOTE="${ROOT}/packaging/sweetpotatos/sweetpotatos-update-notify"
PASS=0
FAIL=0

assert() {
  local cond="$1" label="$2"
  if eval "${cond}"; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}"
    FAIL=$((FAIL + 1))
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/bin" "${tmp}/state" "${tmp}/home"

cat >"${tmp}/sweetpotatos.conf" <<'EOF'
[sweetpotatos]
SigLevel = Optional TrustAll
Server = https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo
EOF

cat >"${tmp}/bin/pacman" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${PACMAN_LOG}"
case "$*" in
  *"-Si"*)
    case "$*" in
      *sweetpotatos/tuber*|*sweetpotatos/sweetpotatos*) exit 0 ;;
      *) exit 1 ;;
    esac
    ;;
  *"--print-format"*)
    if [[ -f "${PACMAN_PRINT}" ]]; then
      cat "${PACMAN_PRINT}"
    fi
    exit 0
    ;;
  *"-Sy"*) exit 0 ;;
esac
echo "unexpected pacman: $*" >&2
exit 1
EOF
chmod 755 "${tmp}/bin/pacman"

cat >"${tmp}/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${NOTIFY_LOG}"
exit 0
EOF
chmod 755 "${tmp}/bin/notify-send"

# No logged-in users, so the root check must not call sudo or notify-send.
cat >"${tmp}/bin/loginctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 755 "${tmp}/bin/loginctl"

cat >"${tmp}/bin/sudo" <<'EOF'
#!/usr/bin/env bash
echo "sudo should not run during this test: $*" >&2
exit 1
EOF
chmod 755 "${tmp}/bin/sudo"

export PATH="${tmp}/bin:${ROOT}/packaging/sweetpotatos:${PATH}"
export PACMAN_LOG="${tmp}/pacman.log"
export PACMAN_PRINT="${tmp}/print.txt"
export NOTIFY_LOG="${tmp}/notify.log"
export SWEETPOTATOS_UPDATE_APPLY_ONLY=1
export SWEETPOTATOS_UPDATE_CONF="${tmp}/sweetpotatos.conf"
export SWEETPOTATOS_UPDATE_CHANNEL_FILE="${tmp}/channel"
export SWEETPOTATOS_UPDATE_STATE_DIR="${tmp}/state"
export SWEETPOTATOS_NOTIFY_NO_SLEEP=1
export HOME="${tmp}/home"
export XDG_STATE_HOME="${tmp}/home/.local/state"
: >"${PACMAN_LOG}"
: >"${NOTIFY_LOG}"

printf '%s\n' tuber sweetpotatos >"${PACMAN_PRINT}"
got="$(bash "${UPD}" --check)"
assert "[[ \"${got}\" == $'tuber\nsweetpotatos' ]]" "check prints only packages that would change"
assert "! grep -q 'Update channel' <<<\"${got}\"" "check does not mix status text into the package list"

: >"${PACMAN_PRINT}"
got="$(bash "${UPD}" --check)"
assert "[[ -z \"${got}\" ]]" "check is quiet when nothing would change"

printf '%s\n' tuber >"${PACMAN_PRINT}"
bash "${NOTE}" check
assert "[[ \"\$(cat \"${tmp}/state/pending-updates\")\" == tuber ]]" "check records the pending package"
assert "[[ ! -f \"${tmp}/state/update-notified\" ]]" "check does not mark the notice sent without a session"

bash "${NOTE}" show
assert "grep -q 'SweetPotatOs updates' \"${NOTIFY_LOG}\"" "login notice shows the title"
assert "grep -q 'sudo sweetpotatos-update' \"${NOTIFY_LOG}\"" "login notice tells the user the command"
assert "grep -q tuber \"${NOTIFY_LOG}\"" "login notice names the package"
lines="$(wc -l <"${NOTIFY_LOG}" | tr -d ' ')"
bash "${NOTE}" show
assert "[[ \"\$(wc -l <\"${NOTIFY_LOG}\" | tr -d ' ')\" == \"${lines}\" ]]" "the same check does not notify twice"

printf '%s\n' tuber sweetpotatos >"${tmp}/state/pending-updates"
sleep 0.05
touch "${tmp}/state/update-notified"
: >"${NOTIFY_LOG}"
bash "${NOTE}" show
assert "[[ ! -s \"${NOTIFY_LOG}\" ]]" "a notice already delivered is not repeated at login"

SWEETPOTATOS_UPDATE_LIVE=1 bash "${NOTE}" show
assert "[[ ! -s \"${NOTIFY_LOG}\" ]]" "live ISO does not show the notice"

: >"${PACMAN_PRINT}"
bash "${NOTE}" check
assert "[[ ! -f \"${tmp}/state/pending-updates\" ]]" "a clear check removes the pending notice"

cat >"${tmp}/news" <<'EOF'
A desktop note now appears after an update.
EOF
export SWEETPOTATOS_UPDATE_NEWS="${tmp}/news"
: >"${NOTIFY_LOG}"
printf '%s\n' tuber >"${tmp}/state/pending-updates"
bash "${NOTE}" applied </dev/null
assert "grep -q 'SweetPotatOs updated' \"${NOTIFY_LOG}\"" "after an update the notice title says updated"
assert "grep -q 'desktop note' \"${NOTIFY_LOG}\"" "after an update the notice quotes what changed"
assert "[[ ! -f \"${tmp}/state/pending-updates\" ]]" "a finished update clears the pending notice"
assert "[[ -s \"${tmp}/state/update-news-shown\" ]]" "the shown note is remembered"

: >"${NOTIFY_LOG}"
bash "${NOTE}" applied </dev/null
assert "[[ ! -s \"${NOTIFY_LOG}\" ]]" "the same note is not shown again"

: >"${NOTIFY_LOG}"
printf '%s\n' tuber | bash "${NOTE}" applied
assert "grep -q 'Updated: tuber' \"${NOTIFY_LOG}\"" "a later package update names the package"

: >"${NOTIFY_LOG}"
printf '%s\n' tuber | SWEETPOTATOS_UPDATE_LIVE=1 bash "${NOTE}" applied
assert "[[ ! -s \"${NOTIFY_LOG}\" ]]" "live ISO does not show the after-update note"

cat >"${tmp}/news" <<'EOF'
# kept
@2026.10.3-83
What changed: notes for every version since the one you had.

@2026.10.3-82
What changed: Cyberpunk tray icons are light.

@2026.10.3-81
What changed: 23 new wallpapers are in the picker.
EOF
rm -f "${tmp}/state/update-news-shown"
: >"${NOTIFY_LOG}"
SWEETPOTATOS_UPDATE_FROM=2026.10.3-81 bash "${NOTE}" applied </dev/null
assert "grep -q 'Cyberpunk tray' \"${NOTIFY_LOG}\"" "a jump shows the note after the installed version"
assert "grep -q 'every version' \"${NOTIFY_LOG}\"" "a jump also shows the newer note"
assert "! grep -q 'wallpapers' \"${NOTIFY_LOG}\"" "a jump does not repeat the note for the version already installed"
tray_line="$(grep -n 'Cyberpunk tray' "${NOTIFY_LOG}" | cut -d: -f1)"
every_line="$(grep -n 'every version' "${NOTIFY_LOG}" | cut -d: -f1)"
assert "[[ \"${tray_line}\" -lt \"${every_line}\" ]]" "notes are shown from the old version toward the new one"
assert "[[ \"\$(grep -c 'SweetPotatOs updated' \"${NOTIFY_LOG}\")\" == 2 ]]" "each change is its own notification"

: >"${NOTIFY_LOG}"
SWEETPOTATOS_UPDATE_FROM=2026.10.3-81 bash "${NOTE}" applied </dev/null
assert "[[ ! -s \"${NOTIFY_LOG}\" ]]" "notes already shown are not repeated"

: >"${NOTIFY_LOG}"
printf '%s\n' tuber | SWEETPOTATOS_UPDATE_FROM=2026.10.3-83 bash "${NOTE}" applied
assert "grep -q 'Updated: tuber' \"${NOTIFY_LOG}\"" "with no new note, the notice names the package"

cat >"${tmp}/pacman.log" <<'EOF'
[2026-10-02T18:00:00+0400] [ALPM] upgraded sweetpotatos (2026.10.3-80 -> 2026.10.3-83)
EOF
rm -f "${tmp}/state/update-news-shown"
: >"${NOTIFY_LOG}"
SWEETPOTATOS_PACMAN_LOG="${tmp}/pacman.log" bash "${NOTE}" applied </dev/null
assert "grep -q 'wallpapers' \"${NOTIFY_LOG}\"" "without a passed version, pacman.log supplies the old one"
assert "grep -q 'Cyberpunk tray' \"${NOTIFY_LOG}\"" "the log path includes the middle note"
assert "grep -q 'every version' \"${NOTIFY_LOG}\"" "the log path includes the newest note"
assert "[[ \"\$(grep -c 'SweetPotatOs updated' \"${NOTIFY_LOG}\")\" == 3 ]]" "the log path sends one notification per note"

echo
echo "update/notify: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
