#!/usr/bin/env bash
# RUNBOOK §3's weekly check. A dump nobody has restored is a guess, not a
# backup — this rebuilds the newest one into a throwaway container and compares
# row counts against the live database.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/brandnest-backups}"
CONTAINER="brandnest-restore-check"
TABLES="brand product product_variant price_history points_ledger"

cd "$(dirname "$0")/.."
dump="$(ls -1t "$BACKUP_DIR"/brandnest-*.dump 2>/dev/null | head -1)"
[ -n "$dump" ] || { echo "no dump found in $BACKUP_DIR"; exit 1; }
echo "verifying $dump"

cleanup() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT
cleanup

docker run -d --name "$CONTAINER" -e POSTGRES_PASSWORD=verify -e POSTGRES_USER=brandnest \
  -e POSTGRES_DB=brandnest pgvector/pgvector:pg16 >/dev/null
until docker exec "$CONTAINER" pg_isready -U brandnest -q 2>/dev/null; do sleep 2; done

docker exec -i "$CONTAINER" pg_restore -U brandnest -d brandnest --no-owner < "$dump" >/dev/null 2>&1 || true

failed=0
for table in $TABLES; do
  live=$(docker compose exec -T postgres psql -U brandnest -d brandnest -tAc "SELECT COUNT(*) FROM $table" | tr -d '\r')
  restored=$(docker exec "$CONTAINER" psql -U brandnest -d brandnest -tAc "SELECT COUNT(*) FROM $table" | tr -d '\r')
  if [ "$live" = "$restored" ]; then
    printf '  %-16s %8s  ok\n' "$table" "$restored"
  else
    printf '  %-16s live=%s restored=%s  MISMATCH\n' "$table" "$live" "$restored"
    failed=1
  fi
done

[ "$failed" -eq 0 ] && echo "restore verified" || { echo "RESTORE CHECK FAILED"; exit 1; }
