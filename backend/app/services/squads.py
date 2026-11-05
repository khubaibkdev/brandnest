"""Shaadi Squad (US-21).

One squad is one event — a mehndi, a baraat — and the family planning outfits
for it. Anyone holding the invite code can join, so the code is the only secret:
every other read and write goes through `membership`, which treats "no such
squad" and "not a member" as the same answer.

Budgets count only items assigned to someone. An unassigned pin is an idea on
the board; once it is someone's outfit, it is money that person plans to spend.
"""

import secrets
from dataclasses import dataclass
from datetime import date
from decimal import Decimal

from sqlalchemy import delete, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import (
    Brand,
    ProductVariant,
    SquadComment,
    SquadEvent,
    SquadItem,
    SquadMember,
    SquadVote,
)
from app.services import watches

EVENT_TYPES = ("mehndi", "baraat", "walima", "eid", "other")
# No 0/O or 1/I: relatives will read these codes aloud and type them.
INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
INVITE_LENGTH = 8


class SquadNotFound(Exception):
    """No such squad, or the caller is not in it."""


class NotAllowed(Exception):
    """A member asked for something only another member may do."""


class UnknownBrand(Exception):
    pass


@dataclass
class SquadSummary:
    squad: SquadEvent
    member_count: int
    item_count: int


def create_squad(
    session: Session,
    user_id: int,
    *,
    name: str,
    event_type: str,
    event_date: date | None,
    budget_total: Decimal | None,
    display_name: str,
) -> SquadEvent:
    squad = SquadEvent(
        owner_id=user_id,
        name=name,
        event_type=event_type,
        event_date=event_date,
        budget_total=budget_total,
        invite_code=_new_invite_code(session),
    )
    session.add(squad)
    session.flush()
    session.add(
        SquadMember(
            squad_event_id=squad.id,
            user_id=user_id,
            display_name=display_name,
            role="owner",
        )
    )
    session.commit()
    return squad


def find_by_invite(session: Session, invite_code: str) -> SquadEvent | None:
    return session.scalar(
        select(SquadEvent).where(SquadEvent.invite_code == invite_code.strip().upper())
    )


def join(
    session: Session, user_id: int, squad: SquadEvent, display_name: str
) -> SquadMember:
    """Join a squad; tapping the same invite twice keeps the first membership."""
    existing = _member_row(session, squad.id, user_id)
    if existing is not None:
        return existing
    member = SquadMember(
        squad_event_id=squad.id, user_id=user_id, display_name=display_name
    )
    session.add(member)
    try:
        session.commit()
    except IntegrityError:
        # The same invite tapped twice at once; the other request won.
        session.rollback()
        return _member_row(session, squad.id, user_id)
    return member


def membership(session: Session, squad_id: int, user_id: int) -> SquadMember:
    member = _member_row(session, squad_id, user_id)
    if member is None:
        raise SquadNotFound
    return member


def member_count(session: Session, squad_id: int) -> int:
    return session.scalar(
        select(func.count()).where(SquadMember.squad_event_id == squad_id)
    )


def squads_for_user(session: Session, user_id: int) -> list[SquadSummary]:
    squads = session.scalars(
        select(SquadEvent)
        .join(SquadMember, SquadMember.squad_event_id == SquadEvent.id)
        .where(SquadMember.user_id == user_id)
        .order_by(SquadEvent.event_date.asc().nulls_last(), SquadEvent.id.desc())
    ).all()
    return [
        SquadSummary(
            squad=squad,
            member_count=member_count(session, squad.id),
            item_count=session.scalar(
                select(func.count()).where(SquadItem.squad_event_id == squad.id)
            ),
        )
        for squad in squads
    ]


def update_member(
    session: Session,
    member: SquadMember,
    *,
    display_name: str | None,
    budget_personal: Decimal | None,
    clear_budget: bool,
) -> None:
    if display_name is not None:
        member.display_name = display_name
    if budget_personal is not None or clear_budget:
        member.budget_personal = budget_personal
    session.commit()


def pin_item(
    session: Session,
    member: SquadMember,
    *,
    brand_slug: str,
    url: str,
    title: str,
    image_url: str | None,
    price: Decimal | None,
) -> SquadItem:
    """Pin a product page to the board. Pinning the same page twice keeps one
    pin. A crawled page is linked to its product so the board shows today's
    price and the catalog's own title and image."""
    brand = session.scalar(select(Brand).where(Brand.slug == brand_slug))
    if brand is None:
        raise UnknownBrand
    clean_url = watches.normalize_url(url)
    existing = session.scalar(
        select(SquadItem).where(
            SquadItem.squad_event_id == member.squad_event_id,
            SquadItem.url == clean_url,
        )
    )
    if existing is not None:
        return existing

    product = watches.find_product_by_url(session, brand_slug, clean_url)
    item = SquadItem(
        squad_event_id=member.squad_event_id,
        added_by=member.id,
        brand_id=brand.id,
        product_id=product.id if product else None,
        url=clean_url,
        title=product.title if product else title,
        image_url=(product.image_urls[0] if product and product.image_urls else image_url),
        price=price,
    )
    session.add(item)
    session.commit()
    return item


def item_in_squad(session: Session, squad_id: int, item_id: int) -> SquadItem:
    item = session.get(SquadItem, item_id)
    if item is None or item.squad_event_id != squad_id:
        raise SquadNotFound
    return item


def update_item(
    session: Session,
    item: SquadItem,
    *,
    assigned_to: int | None,
    clear_assignment: bool,
    note: str | None,
) -> None:
    if assigned_to is not None:
        assignee = session.get(SquadMember, assigned_to)
        if assignee is None or assignee.squad_event_id != item.squad_event_id:
            raise SquadNotFound
        item.assigned_to = assignee.id
    elif clear_assignment:
        item.assigned_to = None
    if note is not None:
        item.note = note or None
    session.commit()


def remove_item(session: Session, member: SquadMember, item: SquadItem) -> None:
    """Whoever pinned it, or the squad's owner, may take it down."""
    if item.added_by != member.id and member.role != "owner":
        raise NotAllowed
    session.delete(item)
    session.commit()


def vote(session: Session, member: SquadMember, item: SquadItem, value: int) -> None:
    """+1 or -1 replaces this member's vote; 0 withdraws it."""
    session.execute(
        delete(SquadVote).where(
            SquadVote.item_id == item.id, SquadVote.member_id == member.id
        )
    )
    if value:
        session.add(SquadVote(item_id=item.id, member_id=member.id, value=value))
    session.commit()


def add_comment(
    session: Session, member: SquadMember, item: SquadItem, body: str
) -> SquadComment:
    comment = SquadComment(item_id=item.id, member_id=member.id, body=body)
    session.add(comment)
    session.commit()
    return comment


def board(session: Session, squad: SquadEvent) -> dict:
    """Everything the board screen shows, in one read — it polls this."""
    members = session.scalars(
        select(SquadMember)
        .where(SquadMember.squad_event_id == squad.id)
        .order_by(SquadMember.joined_at, SquadMember.id)
    ).all()
    items = session.scalars(
        select(SquadItem)
        .where(SquadItem.squad_event_id == squad.id)
        .order_by(SquadItem.created_at.desc(), SquadItem.id.desc())
    ).all()
    item_ids = [item.id for item in items]
    brands = {
        brand.id: brand
        for brand in session.scalars(
            select(Brand).where(Brand.id.in_({item.brand_id for item in items}))
        )
    }
    prices = _current_prices(session, items)
    votes = _votes_by_item(session, item_ids)
    comments = _comments_by_item(session, item_ids)

    planned_by_member: dict[int, Decimal] = {}
    for item in items:
        price = prices.get(item.id)
        if item.assigned_to is not None and price is not None:
            planned_by_member[item.assigned_to] = (
                planned_by_member.get(item.assigned_to, Decimal(0)) + price
            )

    return {
        "squad": squad,
        "members": [
            {"member": member, "planned": planned_by_member.get(member.id, Decimal(0))}
            for member in members
        ],
        "planned_total": sum(planned_by_member.values(), Decimal(0)),
        "items": [
            {
                "item": item,
                "brand": brands[item.brand_id],
                "price": prices.get(item.id),
                "votes": votes.get(item.id, {}),
                "comments": comments.get(item.id, []),
            }
            for item in items
        ],
    }


def _new_invite_code(session: Session) -> str:
    while True:
        code = "".join(secrets.choice(INVITE_ALPHABET) for _ in range(INVITE_LENGTH))
        if find_by_invite(session, code) is None:
            return code


def _member_row(session: Session, squad_id: int, user_id: int) -> SquadMember | None:
    return session.scalar(
        select(SquadMember).where(
            SquadMember.squad_event_id == squad_id, SquadMember.user_id == user_id
        )
    )


def _current_prices(session: Session, items: list[SquadItem]) -> dict[int, Decimal]:
    """Today's lowest in-stock price for crawled items, else the pinned snapshot."""
    product_ids = {item.product_id for item in items if item.product_id}
    lowest = dict(
        session.execute(
            select(ProductVariant.product_id, func.min(ProductVariant.price))
            .where(
                ProductVariant.product_id.in_(product_ids),
                ProductVariant.in_stock.is_(True),
            )
            .group_by(ProductVariant.product_id)
        ).all()
    )
    prices = {}
    for item in items:
        price = lowest.get(item.product_id, item.price)
        if price is not None:
            prices[item.id] = price
    return prices


def _votes_by_item(session: Session, item_ids: list[int]) -> dict[int, dict[int, int]]:
    """item id -> {member id: vote}."""
    result: dict[int, dict[int, int]] = {}
    if not item_ids:
        return result
    for vote_row in session.scalars(
        select(SquadVote).where(SquadVote.item_id.in_(item_ids))
    ):
        result.setdefault(vote_row.item_id, {})[vote_row.member_id] = vote_row.value
    return result


def _comments_by_item(
    session: Session, item_ids: list[int]
) -> dict[int, list[SquadComment]]:
    result: dict[int, list[SquadComment]] = {}
    if not item_ids:
        return result
    for comment in session.scalars(
        select(SquadComment)
        .where(SquadComment.item_id.in_(item_ids))
        .order_by(SquadComment.created_at, SquadComment.id)
    ):
        result.setdefault(comment.item_id, []).append(comment)
    return result
