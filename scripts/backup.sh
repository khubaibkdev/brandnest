#!/usr/bin/env bash
# RUNBOOK §3. The price-history archive is the compounding asset and cannot be
# recomputed, so this runs nightly and is expected to be boring.
#
# Custom format (-Fc), not plain SQL: pg_restore can then rebuild into a
# scratch container, which is how §3's weekly restore check is done.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/brandnest-backups}"
KEEP="${BACKUP_KEEP:-14}"

cd "$(dirname "$0")/.."
mkdir -p "$BACKUP_DIR"

stamp="$(date +%Y-%m-%d-%H%M)"
final="$BACKUP_DIR/brandnest-$stamp.dump"
# Written under a partial name and renamed only on success: a dump truncated by
# a power cut must never sit in the directory looking like a good one.
partial="$final.partial"

docker compose exec -T postgres pg_dump -U brandnest -d brandnest -Fc > "$partial"
mv "$partial" "$final"

# Keep the newest $KEEP, drop the rest.
ls -1t "$BACKUP_DIR"/brandnest-*.dump 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
  rm -f "$old"
done

echo "backup ok: $final ($(du -h "$final" | cut -f1))"
