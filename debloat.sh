#!/bin/sh
# Remove pacotes para o usuário 0 e aplica ajustes de settings, sem root.
# Uso: sh debloat.sh [--dry-run] [--com-opcionais]
# Execução: adb shell sh /sdcard/mm-android-debloat/debloat.sh (PC) ou via aShell/Shizuku.

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/common.sh"

INCLUIR_OPCIONAIS=0

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      --com-opcionais) INCLUIR_OPCIONAIS=1 ;;
      *) log "argumento desconhecido: $arg"; exit 2 ;;
    esac
  done
}

disable_list() {
  read_list "$1" | while IFS= read -r pacote; do
    disable_package "$pacote"
  done
}

apply_tuning() {
  read_list "$HERE/settings/tuning.txt" | while read -r ns key valor; do
    set_setting "$ns" "$key" "$valor"
  done
}

main() {
  parse_args "$@"
  if ! command -v pm >/dev/null 2>&1 || ! command -v settings >/dev/null 2>&1; then
    log "pm/settings indisponíveis neste shell"
    exit 1
  fi
  log "== pacotes (conservadores) =="
  disable_list "$HERE/packages/conservative.txt"
  if [ "$INCLUIR_OPCIONAIS" = "1" ]; then
    log "== pacotes (opcionais) =="
    disable_list "$HERE/packages/optional.txt"
  fi
  log "== settings =="
  apply_tuning
  log "backup: $BACKUP_FILE"
}

main "$@"
