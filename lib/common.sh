#!/bin/sh
# Compartilhado entre debloat.sh e revert.sh. Sem dependências além de pm e settings.

BACKUP_FILE="${BACKUP_FILE:-/sdcard/mm-debloat-backup.txt}"
DRY_RUN="${DRY_RUN:-0}"

log() {
  printf '%s\n' "$*"
}

run_cmd() {
  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] $*"
    return 0
  fi
  "$@" >/dev/null
}

package_enabled() {
  pm list packages -e --user 0 2>/dev/null | grep -qx "package:$1"
}

disable_package() {
  if ! package_enabled "$1"; then
    log "skip $1 (ausente ou já desativado)"
    return 0
  fi
  if run_cmd pm uninstall -k --user 0 "$1"; then
    log "off  $1"
  else
    log "FAIL $1"
  fi
}

enable_package() {
  if run_cmd pm install-existing --user 0 "$1"; then
    log "on   $1"
  else
    log "skip $1 (não instalado neste perfil)"
  fi
}

setting_exists() {
  settings list "$1" 2>/dev/null | grep -q "^$2="
}

backup_setting() {
  grep -q "^$1 $2 " "$BACKUP_FILE" 2>/dev/null && return 0
  [ "$DRY_RUN" = "1" ] && return 0
  printf '%s %s %s\n' "$1" "$2" "$3" >> "$BACKUP_FILE"
}

set_setting() {
  if ! setting_exists "$1" "$2"; then
    log "skip $1/$2 (chave não existe neste aparelho)"
    return 0
  fi
  old="$(settings get "$1" "$2")"
  if [ "$old" = "$3" ]; then
    log "keep $1/$2=$3"
    return 0
  fi
  backup_setting "$1" "$2" "$old"
  if run_cmd settings put "$1" "$2" "$3"; then
    log "set  $1/$2: $old -> $3"
  else
    log "FAIL $1/$2"
  fi
}

read_list() {
  while IFS= read -r line; do
    case "$line" in
      ''|\#*) continue ;;
      *) printf '%s\n' "$line" ;;
    esac
  done < "$1"
}
