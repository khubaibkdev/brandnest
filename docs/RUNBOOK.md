# Runbook

Operations for a team of one. Architecture in `ARCHITECTURE.md`.

## 1. Local Stack

```bash
docker compose up -d            # postgres, meilisearch, api, worker
docker compose logs -f worker   # watch crawls
docker compose exec api alembic upgrade head   # migrations
```

- App (dev builds) points at the machine's LAN IP.
- Admin/deals desk: `http://localhost:8000/admin`.

## 2. Public Ingress — Cloudflare Tunnel (closed beta)

1. Domain on Cloudflare (free plan).
2. **Set `ADMIN_USER` and `ADMIN_PASSWORD` in `.env` first.** The deals desk at `/admin` writes
   the data the app's "Verified ✓" badge stands on, and it ships with a dev default password.
3. `cloudflared tunnel create brandnest` → route `api.<domain>` to `localhost:8000`.
4. Run `cloudflared` as a service so it survives reboots.

Gives stable HTTPS hostname, no port forwarding, home IP hidden. Suitable for ~500 beta users;
**not** for public launch (see §4).

## 3. Backups (non-negotiable, from week one)

- `scripts/backup.sh` — `pg_dump -Fc` to `$BACKUP_DIR` (default `~/brandnest-backups`),
  keeping the newest `$BACKUP_KEEP` (default 14). Dumps are written `.partial` and renamed only
  on success, so a dump cut short by a power failure never sits there looking usable.
- Scheduled daily at 06:00 by Windows Task Scheduler (`BrandNest nightly backup`), after the
  01:00 crawl, 04:00 reindex and 05:00 order confirmations. Output appends to
  `$BACKUP_DIR/backup.log`. Remove with `schtasks /delete /tn "BrandNest nightly backup"`.
- `scripts/verify-restore.sh` — restores the newest dump into a throwaway container and compares
  row counts against the live database. This is §3's weekly check; a dump nobody has restored is
  a guess, not a backup.
- **Still missing: the copy is on the same machine as the database.** The Cloudflare R2 upload
  this section originally specified is not wired, because it needs credentials that do not exist
  yet. So today's backups protect against a bad migration, a dropped table or a corrupted
  volume — **not** against the disk or machine loss that Top Risk #3 is actually about. Wiring
  R2 (or any off-machine copy) is the remaining work.
- The price-history archive is the compounding asset — it cannot be recomputed if lost.

## 4. VPS Migration (before any public store listing)

Trigger: public launch date set, or first beta outage caused by power/ISP — whichever first.

1. Provision one VPS (Hetzner CPX31-class, ~$15/mo), install Docker.
2. `rsync` the compose directory; restore latest `pg_dump`; `docker compose up -d`.
3. Point the Cloudflare Tunnel (or plain DNS + TLS) at the VPS.
4. Keep the home machine as a warm spare / crawler dev box.

The stack is identical at every stage — migration is data + DNS, not re-architecture.

## 5. Incident Procedures

### Crawler got blocked (403/429 storm from a brand)
1. Middleware has already auto-paused the brand (check admin alert).
2. Do **not** retry aggressively or add proxies. Leave paused ≥48h.
3. Check whether `robots.txt` or the site platform changed; adjust adapter/config.
4. If the block persists: flip the brand to WebView-only (no catalog), and prioritize the
   partnership pitch (free analytics for a product feed) — blocking us costs them sales.

### Wrong deal published ("Verified" badge on a bad deal)
1. Admin → set deal `corrected` (or `rejected`); it disappears from the app immediately.
2. If a push notification went out: send a correction push to the same topic the same day.
3. Record cause in PROGRESS.md decision log (source that lied, verification step that missed it).
4. Reporter reputation: downgrade the source's weight if community-reported.
Trust is the product; corrections are visible and fast, never silent.

### Home machine down (power/ISP)
- App degrades gracefully: Drift caches brand grid + sale calendar offline; WebView browsing of
  brand sites still works without our API.
- On restore: worker catches up on missed crawl windows automatically (APScheduler misfire
  grace); verify backup job ran; check `jobs` table for stuck `locked_at` rows.

### AI spend spike
- Stylist and VTO both sit behind quotas and a hard monthly spend cap in config; the cap
  disables the feature rather than overrunning. Check `jobs` for a retry loop before raising it.

## 6. Release Checklist (app)

1. `flutter build apk --release` (Play Store AAB when listed).
2. Smoke-test on a real low-end Android device: brand grid offline, WebView checkout on 2 test
   brands, toolbar chips render, push received.
3. Bump version; tag; update PROGRESS.md.
