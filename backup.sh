#!/usr/bin/env bash
set -euo pipefail

# Uso:
# curl -sSL https://backup.whazing.com.br/backup_whazing.sh | sudo bash -s -- /home/deploy/whazing/backend/.env
# ou
# sudo bash backup_whazing.sh /home/deploy/whazing/backend/.env

ENV_FILE="${1:-/home/deploy/whazing/backend/.env}"
OUT_DIR="${OUT_DIR:-/var/backups/whazing}"
PREFIX="${PREFIX:-backupwhazing}"
KEEP="${KEEP:-7}"   # quantos backups manter

# Função para log
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: arquivo .env não encontrado em: $ENV_FILE" >&2
  exit 2
fi

log "Lendo env: $ENV_FILE"

# Carrega variáveis do .env (apenas chaves simples, ignorando comentários)
# Evita executar linhas - apenas exporta variáveis simples KEY=VALUE
while IFS= read -r line; do
  # remove espaços no início/fim
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  # pula linhas vazias e comentários
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
  # pega linhas do tipo KEY=VALUE (não exporta comandos)
  if echo "$line" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*='; then
    key="$(echo "$line" | cut -d= -f1)"
    val="$(echo "$line" | cut -d= -f2-)"
    # remove aspas se existirem
    val="$(echo "$val" | sed -e 's/^["'\'']//' -e 's/["'\'']$//')"
    case "$key" in
      DB_DIALECT) DB_DIALECT="$val" ;;
      POSTGRES_HOST) POSTGRES_HOST="$val" ;;
      POSTGRES_PORT|DB_PORT) POSTGRES_PORT="$val" ;;
      POSTGRES_USER) POSTGRES_USER="$val" ;;
      POSTGRES_PASSWORD) POSTGRES_PASSWORD="$val" ;;
      POSTGRES_DB) POSTGRES_DB="$val" ;;
      *) ;; # ignora outras
    esac
  fi
done < "$ENV_FILE"

# valores padrão se não vierem
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"

# verifica dialect
if [[ "${DB_DIALECT:-}" != "postgres" ]]; then
  echo "ERRO: DB_DIALECT não é 'postgres' (valor: '${DB_DIALECT:-unset}'). Saindo." >&2
  exit 3
fi

# checa pg_dump
if ! command -v pg_dump >/dev/null 2>&1; then
  echo "ERRO: pg_dump não encontrado. Instale postgresql-client ou postgresql." >&2
  exit 4
fi

# cria pasta de saída
mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

timestamp="$(date '+%Y%m%d_%H%M%S')"
outfile="${OUT_DIR}/${PREFIX}-${timestamp}.sql.gz"

log "Iniciando backup do banco '${POSTGRES_DB}' em ${POSTGRES_HOST}:${POSTGRES_PORT} para ${outfile}"

# exporta senha de forma temporária para pg_dump via env var
export PGPASSWORD="${POSTGRES_PASSWORD:-}"

# Faz dump em formato plain SQL e comprime com gzip stream
# se preferir backup custom (-F c) com pg_dump -Fc remova --no-owner e ajuste extensão
pg_dump --username="${POSTGRES_USER}" --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --format=plain --no-owner --no-privileges "${POSTGRES_DB}" \
  | gzip > "$outfile"

# limpa variável de ambiente (boa prática)
unset PGPASSWORD

log "Backup finalizado: $outfile"

# ajusta permissões
chmod 600 "$outfile"

# Rotacionamento: mantém apenas os últimos $KEEP arquivos
log "Rotacionando backups, mantendo últimos $KEEP arquivos em $OUT_DIR"
# lista arquivos do prefixo ordenados por tempo (mais novos primeiro), remove os que excedem KEEP
mapfile -t files < <(ls -1t "${OUT_DIR}/${PREFIX}-"*.sql.gz 2>/dev/null || true)

if (( ${#files[@]} > KEEP )); then
  todelete=( "${files[@]:$KEEP}" )
  for f in "${todelete[@]}"; do
    log "Removendo antigo backup: $f"
    rm -f -- "$f"
  done
fi

log "Backup concluído com sucesso."
exit 0
