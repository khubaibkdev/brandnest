"""The deals desk: one person, two queues, a state machine that says no.

Server-rendered Jinja2 with HTMX for the row actions, so verifying a deal never
loses your place in the queue and there is no second frontend to build.
"""

import re
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, Form, HTTPException, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.admin.auth import require_admin
from app.db import db_session
from app.models import Bank, BankOffer, Brand, BrandConfig, DealReport, SaleEvent
from app.services import deals, orders, reports

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])

templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))
templates.env.globals["desk_actions"] = deals.desk_actions

# The desk sits in Pakistan and types local times; the database stores UTC.
PKT = ZoneInfo("Asia/Karachi")

CARD_TYPES = ["credit", "debit", "islamic", "wallet", "bnpl"]
CHANNELS = ["online", "instore", "both"]
PENDING = (deals.DRAFT, deals.NEEDS_VERIFICATION, deals.CORRECTED)


@dataclass
class OfferForm:
    # Strings rather than typed optionals: an untouched HTML input submits "",
    # which no numeric or date type accepts. Converted on the way to the model.
    bank_id: int = Form(...)
    brand_id: str = Form("")
    card_types: list[str] = Form([])
    discount_pct: str = Form("")
    max_discount_amt: str = Form("")
    min_spend: str = Form("")
    channel: str = Form("both")
    valid_from: str = Form("")
    valid_to: str = Form("")
    proof_url: str = Form("")


@dataclass
class SaleForm:
    brand_id: int = Form(...)
    title: str = Form(...)
    discount_text: str = Form("")
    starts_at: str = Form("")
    ends_at: str = Form("")
    proof_url: str = Form("")


@router.get("", response_class=HTMLResponse)
def queue(request: Request, session: Session = Depends(db_session)):
    """Everything waiting on a human, both kinds at once."""
    return templates.TemplateResponse(
        request,
        "queue.html",
        {
            "offers": _offer_rows(session, PENDING),
            "sales": _sale_rows(session, PENDING),
            "counts": _counts(session),
        },
    )


@router.get("/reports", response_class=HTMLResponse)
def list_reports(request: Request, session: Session = Depends(db_session)):
    """Community deal reports (US-14). Undecided first — a decided one is
    history, and the desk is here to clear the queue."""
    return templates.TemplateResponse(
        request,
        "reports.html",
        {
            "rows": reports.pending_reports(session),
            "report_points": reports.REPORT_POINTS,
        },
    )


@router.post("/reports/{report_id}/{decision}", response_class=HTMLResponse)
def decide_report(
    request: Request,
    report_id: int,
    decision: str,
    session: Session = Depends(db_session),
):
    report = _get(session, DealReport, report_id)
    if decision not in ("accept", "reject"):
        raise HTTPException(status_code=400, detail="Unknown decision")
    try:
        decided = (
            reports.accept(session, report)
            if decision == "accept"
            else reports.reject(session, report)
        )
    except reports.AlreadyDecided as error:
        # A double-click, or two tabs open on the same queue. The row that comes
        # back shows the decision that stands, rather than paying twice.
        raise HTTPException(status_code=409, detail=str(error)) from error
    return templates.TemplateResponse(request, "_report_row.html", {"row": decided})


@router.get("/offers", response_class=HTMLResponse)
def list_offers(
    request: Request, status: str | None = None, session: Session = Depends(db_session)
):
    return templates.TemplateResponse(
        request,
        "deals.html",
        {
            "kind": "offers",
            "title": "Bank offers",
            "rows": _offer_rows(session, (status,) if status else None),
            "row_template": "_offer_row.html",
            "status": status,
        },
    )


@router.get("/sales", response_class=HTMLResponse)
def list_sales(
    request: Request, status: str | None = None, session: Session = Depends(db_session)
):
    return templates.TemplateResponse(
        request,
        "deals.html",
        {
            "kind": "sales",
            "title": "Sale events",
            "rows": _sale_rows(session, (status,) if status else None),
            "row_template": "_sale_row.html",
            "status": status,
        },
    )


@router.post("/offers/{offer_id}/status", response_class=HTMLResponse)
def move_offer(
    request: Request,
    offer_id: int,
    to: str = Form(...),
    actor: str = Depends(require_admin),
    session: Session = Depends(db_session),
):
    offer = _get(session, BankOffer, offer_id)
    _apply(session, offer, to, actor)
    return templates.TemplateResponse(
        request, "_offer_row.html", {"row": _offer_rows(session, ids=[offer_id])[0]}
    )


@router.post("/sales/{sale_id}/status", response_class=HTMLResponse)
def move_sale(
    request: Request,
    sale_id: int,
    to: str = Form(...),
    actor: str = Depends(require_admin),
    session: Session = Depends(db_session),
):
    sale = _get(session, SaleEvent, sale_id)
    _apply(session, sale, to, actor)
    return templates.TemplateResponse(
        request, "_sale_row.html", {"row": _sale_rows(session, ids=[sale_id])[0]}
    )


@router.get("/offers/new", response_class=HTMLResponse)
def new_offer_form(request: Request, session: Session = Depends(db_session)):
    return _render_offer_form(request, session, None)


@router.get("/offers/{offer_id}/edit", response_class=HTMLResponse)
def edit_offer_form(
    request: Request, offer_id: int, session: Session = Depends(db_session)
):
    return _render_offer_form(request, session, _get(session, BankOffer, offer_id))


@router.post("/offers")
def create_offer(form: OfferForm = Depends(), session: Session = Depends(db_session)):
    return _save_offer(session, BankOffer(status=deals.DRAFT, source="manual"), form)


@router.post("/offers/{offer_id}/edit")
def update_offer(
    offer_id: int, form: OfferForm = Depends(), session: Session = Depends(db_session)
):
    return _save_offer(session, _get(session, BankOffer, offer_id), form)


def _save_offer(session: Session, offer: BankOffer, form: OfferForm) -> RedirectResponse:
    offer.bank_id = form.bank_id
    offer.brand_id = int(form.brand_id) if form.brand_id else None
    offer.card_types = form.card_types
    offer.discount_pct = _decimal(form.discount_pct)
    offer.max_discount_amt = _decimal(form.max_discount_amt)
    offer.min_spend = _decimal(form.min_spend)
    offer.channel = form.channel
    offer.valid_from = _date(form.valid_from)
    offer.valid_to = _date(form.valid_to)
    offer.proof_url = form.proof_url or None
    session.add(offer)
    session.commit()
    return RedirectResponse("/admin/offers", status_code=303)


@router.get("/sales/new", response_class=HTMLResponse)
def new_sale_form(request: Request, session: Session = Depends(db_session)):
    return _render_sale_form(request, session, None)


@router.get("/sales/{sale_id}/edit", response_class=HTMLResponse)
def edit_sale_form(request: Request, sale_id: int, session: Session = Depends(db_session)):
    return _render_sale_form(request, session, _get(session, SaleEvent, sale_id))


@router.post("/sales")
def create_sale(form: SaleForm = Depends(), session: Session = Depends(db_session)):
    return _save_sale(session, SaleEvent(status=deals.DRAFT, source="manual"), form)


@router.post("/sales/{sale_id}/edit")
def update_sale(
    sale_id: int, form: SaleForm = Depends(), session: Session = Depends(db_session)
):
    return _save_sale(session, _get(session, SaleEvent, sale_id), form)


def _save_sale(session: Session, sale: SaleEvent, form: SaleForm) -> RedirectResponse:
    sale.brand_id = form.brand_id
    sale.title = form.title
    sale.discount_text = form.discount_text or None
    sale.starts_at = _moment(form.starts_at)
    sale.ends_at = _moment(form.ends_at)
    sale.proof_url = form.proof_url or None
    session.add(sale)
    session.commit()
    return RedirectResponse("/admin/sales", status_code=303)


def _render_offer_form(request: Request, session: Session, offer: BankOffer | None):
    return templates.TemplateResponse(
        request,
        "offer_form.html",
        {
            "offer": offer,
            "banks": session.scalars(select(Bank).order_by(Bank.name)).all(),
            "brands": session.scalars(select(Brand).order_by(Brand.name)).all(),
            "card_types": CARD_TYPES,
            "channels": CHANNELS,
        },
    )


def _render_sale_form(request: Request, session: Session, sale: SaleEvent | None):
    return templates.TemplateResponse(
        request,
        "sale_form.html",
        {
            "sale": sale,
            "brands": session.scalars(select(Brand).order_by(Brand.name)).all(),
            "local": _local_input,
        },
    )


def _apply(session: Session, deal, to_status: str, actor: str) -> None:
    if to_status not in deals.DESK_ACTIONS:
        raise HTTPException(status_code=400, detail=f"{to_status} is not the desk's call")
    try:
        deals.transition(deal, to_status, actor)
    except deals.TransitionError as refused:
        raise HTTPException(status_code=400, detail=str(refused)) from refused
    session.commit()


def _get(session: Session, model, deal_id: int):
    deal = session.get(model, deal_id)
    if deal is None:
        raise HTTPException(status_code=404, detail="No such deal")
    return deal


def _offer_rows(
    session: Session, statuses: tuple[str, ...] | None = None, ids: list[int] | None = None
):
    stmt = (
        select(BankOffer, Bank.name, Brand.name)
        .join(Bank, Bank.id == BankOffer.bank_id)
        .outerjoin(Brand, Brand.id == BankOffer.brand_id)
        .order_by(BankOffer.id.desc())
    )
    if statuses:
        stmt = stmt.where(BankOffer.status.in_(statuses))
    if ids:
        stmt = stmt.where(BankOffer.id.in_(ids))
    return session.execute(stmt).all()


def _sale_rows(
    session: Session, statuses: tuple[str, ...] | None = None, ids: list[int] | None = None
):
    stmt = (
        select(SaleEvent, Brand.name)
        .join(Brand, Brand.id == SaleEvent.brand_id)
        .order_by(SaleEvent.id.desc())
    )
    if statuses:
        stmt = stmt.where(SaleEvent.status.in_(statuses))
    if ids:
        stmt = stmt.where(SaleEvent.id.in_(ids))
    return session.execute(stmt).all()


def _counts(session: Session) -> dict[str, int]:
    def total(model, statuses=None) -> int:
        stmt = select(func.count()).select_from(model)
        if statuses:
            stmt = stmt.where(model.status.in_(statuses))
        return session.scalar(stmt)

    return {
        "offers": total(BankOffer),
        "sales": total(SaleEvent),
        "published_offers": total(BankOffer, deals.PUBLISHED),
        "published_sales": total(SaleEvent, deals.PUBLISHED),
    }


def _decimal(value: str) -> Decimal | None:
    return Decimal(value) if value.strip() else None


def _date(value: str) -> date | None:
    return date.fromisoformat(value) if value.strip() else None


def _moment(value: str) -> datetime | None:
    """`datetime-local` has no zone; the desk means Pakistan time."""
    return datetime.fromisoformat(value).replace(tzinfo=PKT) if value.strip() else None


def _local_input(moment: datetime | None) -> str:
    """Back into the `datetime-local` format the desk typed it in."""
    return moment.astimezone(PKT).strftime("%Y-%m-%dT%H:%M") if moment else ""


@router.get("/brands", response_class=HTMLResponse)
def list_brand_checkouts(request: Request, session: Session = Depends(db_session)):
    """US-18's per-brand order-confirmation patterns. Active brands only —
    an inactive brand cannot be shopped, so it cannot produce an order."""
    brands = session.scalars(
        select(Brand).where(Brand.is_active).order_by(Brand.name)
    ).all()
    return templates.TemplateResponse(
        request,
        "brands.html",
        {"brands": brands, "hold_days": orders.HOLD_DAYS},
    )


@router.post("/brands/{brand_id}/order-patterns")
def save_order_patterns(
    brand_id: int,
    patterns: str = Form(""),
    session: Session = Depends(db_session),
):
    config = session.get(BrandConfig, brand_id)
    if config is None:
        raise HTTPException(status_code=404, detail="Unknown brand")
    cleaned = [line.strip() for line in patterns.splitlines() if line.strip()]
    for pattern in cleaned:
        try:
            re.compile(pattern)
        except re.error as error:
            # Refuse the save rather than store a pattern that silently never
            # matches — a brand whose patterns are broken pays nobody.
            raise HTTPException(status_code=400, detail=f"Bad pattern {pattern!r}: {error}")
    config.order_confirm_patterns = cleaned
    session.commit()
    return RedirectResponse("/admin/brands", status_code=303)
