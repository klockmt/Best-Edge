#!/bin/sh
# Testes de integração com mocks de pm e settings. Falha ao primeiro erro.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
export PATH="$ROOT/tests/fake_bin:$PATH"
export FAKE_STATE="$TMP/state"
export BACKUP_FILE="$TMP/backup.txt"
mkdir -p "$FAKE_STATE"

afirmar() { [ "$1" = "$2" ] || { echo "FALHOU: $3 (esperado=$2 obtido=$1)"; exit 1; }; }
afirmar_contem() { echo "$1" | grep -qF "$2" || { echo "FALHOU: saída não contém '$2'"; exit 1; }; }

preparar_estado() {
  printf '%s\n' com.facebook.katana com.motorola.gamemode com.outro.app > "$FAKE_STATE/packages"
  printf '%s\n' "peak_refresh_rate=120" "screen_off_timeout=15000" > "$FAKE_STATE/settings_system"
  printf '%s\n' "animator_duration_scale=1.0" > "$FAKE_STATE/settings_global"
  printf '%s\n' "doze_enabled=0" > "$FAKE_STATE/settings_secure"
  : > "$FAKE_STATE/actions"
  rm -f "$BACKUP_FILE"
}

preparar_estado
saida=$(DRY_RUN=1 sh "$ROOT/debloat.sh" --dry-run)
afirmar_contem "$saida" "[dry-run] pm uninstall -k --user 0 com.facebook.katana"
afirmar "$(cat "$FAKE_STATE/actions")" "" "dry-run não deve executar ações"
afirmar "$(test -f "$BACKUP_FILE" && echo sim || echo nao)" "nao" "dry-run não deve gravar backup"

preparar_estado
sh "$ROOT/debloat.sh" >/dev/null
afirmar "$(grep -c com.facebook.katana "$FAKE_STATE/actions")" "1" "pacote conservador desativado uma vez"
afirmar "$(grep -c com.motorola.gamemode "$FAKE_STATE/actions")" "0" "opcional não desativado sem flag"
afirmar "$(grep -c com.outro.app "$FAKE_STATE/actions")" "0" "pacote fora da lista intocado"
afirmar "$(grep '^system peak_refresh_rate ' "$BACKUP_FILE" | cut -d' ' -f3)" "120" "backup guarda valor original"
afirmar "$(settings get system screen_off_timeout)" "30000" "setting existente aplicado"
afirmar "$(settings get global ambient_enabled)" "null" "chave inexistente não é criada"

preparar_estado
sh "$ROOT/debloat.sh" --com-opcionais >/dev/null
afirmar "$(grep -c com.motorola.gamemode "$FAKE_STATE/actions")" "1" "opcional desativado com flag"

sh "$ROOT/debloat.sh" >/dev/null
afirmar "$(grep '^system screen_off_timeout ' "$BACKUP_FILE" | cut -d' ' -f3)" "15000" "segunda execução não sobrescreve backup original"

sh "$ROOT/revert.sh" >/dev/null
afirmar "$(settings get system screen_off_timeout)" "15000" "revert restaura valor original"

rm -rf "$TMP"
echo "OK: todos os testes passaram"
