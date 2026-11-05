import argparse
import logging

from apscheduler.schedulers.blocking import BlockingScheduler

from app.services.crawl import run_full_crawl
from app.services.search_index import run_reindex
from app.services.deals import run_deal_transitions
from app.services.bank_scan import run_bank_scan
from app.services.offer_scan import run_offer_scan
from app.services.orders import run_order_confirmations
from app.services.watch_alerts import run_watch_alerts

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-7s %(name)s: %(message)s",
)


def main() -> None:
    parser = argparse.ArgumentParser(description="BrandNest worker")
    parser.add_argument("--once", action="store_true", help="run one full crawl and exit")
    parser.add_argument("--brands", help="comma-separated brand slugs to crawl")
    parser.add_argument("--reindex", action="store_true", help="rebuild the search index and exit")
    args = parser.parse_args()

    if args.reindex:
        run_reindex()
        return

    slugs = args.brands.split(",") if args.brands else None
    if args.once:
        run_full_crawl(slugs)
        return

    scheduler = BlockingScheduler(timezone="Asia/Karachi")
    # Tier F: nightly full catalog crawl (CRAWLER_PLAYBOOK.md §2)
    scheduler.add_job(run_full_crawl, "cron", hour=1, minute=0)
    # Publish and retire deals on their own dates (ARCHITECTURE.md §8). Hourly is
    # enough: windows are days long, and expiry runs on the hour it falls due.
    scheduler.add_job(run_deal_transitions, "cron", minute=0)
    # Tier-W (CRAWLER_PLAYBOOK §2): re-check watched products every 60 min,
    # independent of the nightly full crawl.
    scheduler.add_job(run_watch_alerts, "interval", minutes=60)
    # US-18: order points sit pending through their return window; daily is
    # ample for a 14-day hold and keeps the ledger honest without polling.
    scheduler.add_job(run_order_confirmations, "cron", hour=5, minute=0)
    # US-3/US-5: bank offers are campaign-shaped, announced by the brand and
    # gone in a fortnight. Weekly on a Monday morning catches a campaign early
    # without re-reading 25 sites for a thing that rarely changes daily.
    scheduler.add_job(run_offer_scan, "cron", day_of_week="mon", hour=6, minute=0)
    # The other half of the same question, from the banks' own listings.
    # Separate job because it needs a browser and takes minutes, not seconds.
    scheduler.add_job(run_bank_scan, "cron", day_of_week="mon", hour=6, minute=30)
    # US-11: the index is a projection of the catalog, so it is rebuilt after
    # the nightly crawl has finished changing it rather than on its own clock.
    scheduler.add_job(run_reindex, "cron", hour=4, minute=0)
    run_deal_transitions()
    logging.getLogger(__name__).info(
        "worker started; nightly crawl at 01:00 PKT, deal transitions hourly, "
        "watch alerts every 60 min, search reindex at 04:00 PKT, "
        "order confirmations at 05:00 PKT, offer scan Mondays 06:00 PKT, "
        "bank scan Mondays 06:30 PKT"
    )
    scheduler.start()


if __name__ == "__main__":
    main()
