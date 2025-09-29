#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-/home/deploy/whazing/backend/.env}"
OUT_DIR="${OUT_DIR:-/var/backups/whazing}"
PREFIX="${PREFIX:-backupwhazing}"
KEEP="${KEEP:-7}"   # quantos backups manter
CONTAINER_NAME="${CONTAINER_NAME:-postgresql}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

log "Lendo env: $ENV_FILE"

# lê variáveis do .env
while IFS= read -r line; do
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
  if echo "$line" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*='; then
    key="$(echo "$line" | cut -d= -f1)"
    val="$(echo "$line" | cut -d= -f2- | sed -e 's/^["'\'' ]*//' -e 's/["'\'' ]*$//')"
    case "$key" in
      DB_DIALECT) DB_DIALECT="$val" ;;
      POSTGRES_USER) POSTGRES_USER="$val" ;;
      POSTGRES_PASSWORD) POSTGRES_PASSWORD="$val" ;;
      POSTGRES_DB) POSTGRES_DB="$val" ;;
    esac
  fi
done < "$ENV_FILE"

if [[ "${DB_DIALECT:-}" != "postgres" ]]; then
  echo "ERRO: DB_DIALECT não é postgres (valor: ${DB_DIALECT:-unset})"
  exit 3
fi

mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

timestamp="$(date '+%Y%m%d_%H%M%S')"
outfile="${OUT_DIR}/${PREFIX}-${timestamp}.sql.gz"

log "Rodando pg_dump dentro do container $CONTAINER_NAME ..."

docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip > "$outfile"

chmod 600 "$outfile"
log "Backup salvo em $outfile"

# Rotacionamento
mapfile -t files < <(ls -1t "${OUT_DIR}/${PREFIX}-"*.sql.gz 2>/dev/null || true)
if (( ${#files[@]} > KEEP )); then
  todelete=( "${files[@]:$KEEP}" )
  for f in "${todelete[@]}"; do
    log "Removendo antigo backup: $f"
    rm -f -- "$f"
  done
fi

log "Backup concluído."
