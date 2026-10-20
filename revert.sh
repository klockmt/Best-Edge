#!/bin/sh
# Reverte o que o debloat.sh alterou: reinstala pacotes para o usuário 0 e restaura settings do backup.
# Uso: sh revert.sh [--dry-run]

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/common.sh"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) log "argumento desconhecido: $arg"; exit 2 ;;
  esac
done

restore_packages() {
  for lista in conservative optional; do
    read_list "$HERE/packages/$lista.txt" | while IFS= read -r pacote; do
      enable_package "$pacote"
    done
  done
}

restore_settings() {
  if [ ! -f "$BACKUP_FILE" ]; then
    log "sem backup em $BACKUP_FILE; settings não restaurados"
    return 1
  fi
  while read -r ns key valor; do
    if [ "$valor" = "null" ]; then
      run_cmd settings delete "$ns" "$key"
    else
      run_cmd settings put "$ns" "$key" "$valor"
    fi
    log "restore $ns/$key=$valor"
  done < "$BACKUP_FILE"
}

log "== pacotes =="
restore_packages
log "== settings =="
restore_settings
