from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.auth import current_user
from app.config import settings
from app.db import db_session
from app.models import SquadEvent, SquadMember, User
from app.services import squads

router = APIRouter(tags=["squads"])

EventType = Literal["mehndi", "baraat", "walima", "eid", "other"]
Name = Field(min_length=1, max_length=40)


class _In(BaseModel):
    # So min_length means "something besides spaces".
    model_config = ConfigDict(str_strip_whitespace=True)


class SquadIn(_In):
    name: str = Field(min_length=1, max_length=80)
    event_type: EventType
    event_date: date | None = None
    budget_total: Decimal | None = Field(default=None, ge=0)
    display_name: str = Name


class JoinIn(_In):
    invite_code: str = Field(min_length=1, max_length=12)
    display_name: str = Name


class MemberUpdateIn(_In):
    display_name: str | None = Field(default=None, min_length=1, max_length=40)
    budget_personal: Decimal | None = Field(default=None, ge=0)


class PinIn(_In):
    brand_slug: str
    url: str = Field(min_length=1, max_length=1000)
    title: str = Field(min_length=1, max_length=300)
    image_url: str | None = Field(default=None, max_length=1000)
    price: Decimal | None = Field(default=None, ge=0)


class ItemUpdateIn(_In):
    assigned_to: int | None = None
    note: str | None = Field(default=None, max_length=300)


class VoteIn(_In):
    value: Literal[-1, 0, 1]


class CommentIn(_In):
    body: str = Field(min_length=1, max_length=500)


class SquadSummaryOut(BaseModel):
    id: int
    name: str
    event_type: str
    event_date: date | None
    member_count: int
    item_count: int


class InviteOut(BaseModel):
    squad_id: int
    name: str
    event_type: str
    event_date: date | None
    member_count: int
    already_member: bool


class MemberOut(BaseModel):
    id: int
    display_name: str
    role: str
    budget_personal: Decimal | None
    planned: Decimal


class CommentOut(BaseModel):
    id: int
    member_id: int
    body: str
    created_at: datetime


class ItemOut(BaseModel):
    id: int
    brand_slug: str
    brand_name: str
    url: str
    title: str
    image_url: str | None
    price: Decimal | None
    added_by: int
    assigned_to: int | None
    note: str | None
    score: int
    my_vote: int
    comments: list[CommentOut]


class BoardOut(BaseModel):
    id: int
    name: str
    event_type: str
    event_date: date | None
    budget_total: Decimal | None
    planned_total: Decimal
    invite_code: str
    invite_url: str
    my_member_id: int
    members: list[MemberOut]
    items: list[ItemOut]


def _member(squad_id: int, user: User, session: Session) -> SquadMember:
    try:
        return squads.membership(session, squad_id, user.id)
    except squads.SquadNotFound:
        raise HTTPException(status_code=404, detail="Squad not found") from None


def _item(squad_id: int, item_id: int, session: Session):
    try:
        return squads.item_in_squad(session, squad_id, item_id)
    except squads.SquadNotFound:
        raise HTTPException(status_code=404, detail="Item not found") from None


def _board(session: Session, squad_id: int, me: SquadMember) -> BoardOut:
    board = squads.board(session, session.get(SquadEvent, squad_id))
    squad = board["squad"]
    return BoardOut(
        id=squad.id,
        name=squad.name,
        event_type=squad.event_type,
        event_date=squad.event_date,
        budget_total=squad.budget_total,
        planned_total=board["planned_total"],
        invite_code=squad.invite_code,
        invite_url=f"{settings.public_base_url.rstrip('/')}/i/{squad.invite_code}",
        my_member_id=me.id,
        members=[
            MemberOut(
                id=row["member"].id,
                display_name=row["member"].display_name,
                role=row["member"].role,
                budget_personal=row["member"].budget_personal,
                planned=row["planned"],
            )
            for row in board["members"]
        ],
        items=[_item_out(row, me) for row in board["items"]],
    )


def _item_out(row: dict, me: SquadMember) -> ItemOut:
    item = row["item"]
    return ItemOut(
        id=item.id,
        brand_slug=row["brand"].slug,
        brand_name=row["brand"].name,
        url=item.url,
        title=item.title,
        image_url=item.image_url,
        price=row["price"],
        added_by=item.added_by,
        assigned_to=item.assigned_to,
        note=item.note,
        score=sum(row["votes"].values()),
        my_vote=row["votes"].get(me.id, 0),
        comments=[
            CommentOut(
                id=comment.id,
                member_id=comment.member_id,
                body=comment.body,
                created_at=comment.created_at,
            )
            for comment in row["comments"]
        ],
    )


@router.post("/me/squads", response_model=BoardOut, status_code=201)
def create_squad(
    payload: SquadIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    squad = squads.create_squad(
        session,
        user.id,
        name=payload.name,
        event_type=payload.event_type,
        event_date=payload.event_date,
        budget_total=payload.budget_total,
        display_name=payload.display_name,
    )
    return _board(session, squad.id, squads.membership(session, squad.id, user.id))


@router.get("/me/squads", response_model=list[SquadSummaryOut])
def my_squads(
    user: User = Depends(current_user), session: Session = Depends(db_session)
) -> list[SquadSummaryOut]:
    return [
        SquadSummaryOut(
            id=summary.squad.id,
            name=summary.squad.name,
            event_type=summary.squad.event_type,
            event_date=summary.squad.event_date,
            member_count=summary.member_count,
            item_count=summary.item_count,
        )
        for summary in squads.squads_for_user(session, user.id)
    ]


@router.get("/me/squads/invites/{invite_code}", response_model=InviteOut)
def preview_invite(
    invite_code: str,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> InviteOut:
    """What the join screen shows before someone commits to a name."""
    squad = squads.find_by_invite(session, invite_code)
    if squad is None:
        raise HTTPException(status_code=404, detail="Invite not found")
    try:
        squads.membership(session, squad.id, user.id)
        already_member = True
    except squads.SquadNotFound:
        already_member = False
    return InviteOut(
        squad_id=squad.id,
        name=squad.name,
        event_type=squad.event_type,
        event_date=squad.event_date,
        member_count=squads.member_count(session, squad.id),
        already_member=already_member,
    )


@router.post("/me/squads/join", response_model=BoardOut)
def join_squad(
    payload: JoinIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    squad = squads.find_by_invite(session, payload.invite_code)
    if squad is None:
        raise HTTPException(status_code=404, detail="Invite not found")
    member = squads.join(session, user.id, squad, payload.display_name)
    return _board(session, squad.id, member)


@router.get("/me/squads/{squad_id}", response_model=BoardOut)
def get_board(
    squad_id: int,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    return _board(session, squad_id, _member(squad_id, user, session))


@router.patch("/me/squads/{squad_id}/me", response_model=BoardOut)
def update_me(
    squad_id: int,
    payload: MemberUpdateIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    member = _member(squad_id, user, session)
    squads.update_member(
        session,
        member,
        display_name=payload.display_name,
        budget_personal=payload.budget_personal,
        clear_budget="budget_personal" in payload.model_fields_set,
    )
    return _board(session, squad_id, member)


@router.post("/me/squads/{squad_id}/items", response_model=BoardOut, status_code=201)
def pin_item(
    squad_id: int,
    payload: PinIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    member = _member(squad_id, user, session)
    try:
        squads.pin_item(
            session,
            member,
            brand_slug=payload.brand_slug,
            url=payload.url,
            title=payload.title,
            image_url=payload.image_url,
            price=payload.price,
        )
    except squads.UnknownBrand:
        raise HTTPException(status_code=422, detail="Unknown brand") from None
    return _board(session, squad_id, member)


@router.patch("/me/squads/{squad_id}/items/{item_id}", response_model=BoardOut)
def update_item(
    squad_id: int,
    item_id: int,
    payload: ItemUpdateIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    member = _member(squad_id, user, session)
    try:
        squads.update_item(
            session,
            _item(squad_id, item_id, session),
            assigned_to=payload.assigned_to,
            clear_assignment="assigned_to" in payload.model_fields_set,
            note=payload.note,
        )
    except squads.SquadNotFound:
        raise HTTPException(status_code=422, detail="Not a member of this squad") from None
    return _board(session, squad_id, member)


@router.delete("/me/squads/{squad_id}/items/{item_id}", response_model=BoardOut)
def remove_item(
    squad_id: int,
    item_id: int,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    member = _member(squad_id, user, session)
    try:
        squads.remove_item(session, member, _item(squad_id, item_id, session))
    except squads.NotAllowed:
        raise HTTPException(
            status_code=403, detail="Only whoever pinned it, or the owner, can remove it"
        ) from None
    return _board(session, squad_id, member)


@router.put("/me/squads/{squad_id}/items/{item_id}/vote", response_model=BoardOut)
def vote(
    squad_id: int,
    item_id: int,
    payload: VoteIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    member = _member(squad_id, user, session)
    squads.vote(session, member, _item(squad_id, item_id, session), payload.value)
    return _board(session, squad_id, member)


@router.post(
    "/me/squads/{squad_id}/items/{item_id}/comments",
    response_model=BoardOut,
    status_code=201,
)
def add_comment(
    squad_id: int,
    item_id: int,
    payload: CommentIn,
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> BoardOut:
    member = _member(squad_id, user, session)
    squads.add_comment(
        session, member, _item(squad_id, item_id, session), payload.body
    )
    return _board(session, squad_id, member)
