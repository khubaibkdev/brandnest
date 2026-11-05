"""US-21: Shaadi Squad — create, invite, join, pin, assign, budget, vote, comment."""

from decimal import Decimal

import pytest

from app.models import Brand, Product, ProductVariant

OWNER = "firebase-uid-owner"
COUSIN = "firebase-uid-cousin"
STRANGER = "firebase-uid-stranger"
PRODUCT_URL = "https://example.pk/products/red-lehenga"


@pytest.fixture
def brand(session):
    brand = Brand(slug="test-brand", name="Test Brand", website_url="https://example.pk")
    session.add(brand)
    session.flush()
    return brand


@pytest.fixture
def product(session, brand):
    product = Product(
        brand_id=brand.id,
        external_id="1",
        source_url=PRODUCT_URL,
        title="Red Lehenga",
        image_urls=["https://cdn.example.pk/red.jpg"],
        is_available=True,
    )
    session.add(product)
    session.flush()
    for external_id, price, in_stock in [("a", "18000", True), ("b", "15000", True), ("c", "9000", False)]:
        session.add(
            ProductVariant(
                product_id=product.id,
                external_id=external_id,
                price=Decimal(price),
                in_stock=in_stock,
            )
        )
    session.flush()
    return product


@pytest.fixture
def squad(client, as_signed_in):
    as_signed_in(OWNER)
    response = client.post(
        "/me/squads",
        json={
            "name": "Ayesha's Mehndi",
            "event_type": "mehndi",
            "event_date": "2026-12-20",
            "budget_total": "100000",
            "display_name": "Ammi",
        },
    )
    assert response.status_code == 201
    return response.json()


def _join(client, as_signed_in, squad, uid=COUSIN, name="Sana"):
    as_signed_in(uid)
    response = client.post(
        "/me/squads/join", json={"invite_code": squad["invite_code"], "display_name": name}
    )
    assert response.status_code == 200
    return response.json()


def _pin(client, squad, url=PRODUCT_URL, **extra):
    return client.post(
        f"/me/squads/{squad['id']}/items",
        json={"brand_slug": "test-brand", "url": url, "title": "From the page", **extra},
    )


def test_creating_a_squad_makes_the_creator_its_owner(squad):
    assert squad["name"] == "Ayesha's Mehndi"
    assert len(squad["invite_code"]) == 8
    assert squad["invite_url"].endswith(f"/i/{squad['invite_code']}")
    [owner] = squad["members"]
    assert owner["display_name"] == "Ammi"
    assert owner["role"] == "owner"
    assert squad["my_member_id"] == owner["id"]


def test_a_blank_name_is_rejected(client, as_signed_in):
    as_signed_in(OWNER)
    response = client.post(
        "/me/squads",
        json={"name": "   ", "event_type": "mehndi", "display_name": "Ammi"},
    )
    assert response.status_code == 422


def test_an_invite_previews_without_joining(client, as_signed_in, squad):
    as_signed_in(COUSIN)
    preview = client.get(f"/me/squads/invites/{squad['invite_code'].lower()}").json()

    assert preview["name"] == "Ayesha's Mehndi"
    assert preview["member_count"] == 1
    assert preview["already_member"] is False
    assert client.get(f"/me/squads/{squad['id']}").status_code == 404


def test_joining_twice_keeps_one_membership(client, as_signed_in, squad):
    _join(client, as_signed_in, squad)
    board = _join(client, as_signed_in, squad, name="Sana again")

    assert [member["display_name"] for member in board["members"]] == ["Ammi", "Sana"]


def test_a_stranger_cannot_read_or_write_the_board(client, as_signed_in, squad, brand):
    as_signed_in(STRANGER)

    assert client.get(f"/me/squads/{squad['id']}").status_code == 404
    assert _pin(client, squad).status_code == 404


def test_my_squads_lists_only_my_squads(client, as_signed_in, squad):
    _join(client, as_signed_in, squad)
    assert [row["id"] for row in client.get("/me/squads").json()] == [squad["id"]]

    as_signed_in(STRANGER)
    assert client.get("/me/squads").json() == []


def test_a_crawled_page_pins_with_the_catalogs_details_and_lowest_in_stock_price(
    client, as_signed_in, squad, product
):
    as_signed_in(OWNER)
    board = _pin(client, squad, url=PRODUCT_URL + "?variant=7").json()

    [item] = board["items"]
    assert item["title"] == "Red Lehenga"
    assert item["image_url"] == "https://cdn.example.pk/red.jpg"
    assert item["price"] == "15000.00"
    assert item["brand_name"] == "Test Brand"


def test_an_uncrawled_page_keeps_its_snapshot(client, as_signed_in, squad, brand):
    as_signed_in(OWNER)
    board = _pin(
        client,
        squad,
        url="https://example.pk/products/new-arrival",
        image_url="https://cdn.example.pk/new.jpg",
        price="7500",
    ).json()

    [item] = board["items"]
    assert item["title"] == "From the page"
    assert item["price"] == "7500.00"


def test_pinning_the_same_page_twice_keeps_one_pin(client, as_signed_in, squad, product):
    as_signed_in(OWNER)
    _pin(client, squad)
    board = _pin(client, squad, url=PRODUCT_URL + "#reviews").json()

    assert len(board["items"]) == 1


def test_an_unknown_brand_cannot_be_pinned(client, as_signed_in, squad):
    as_signed_in(OWNER)
    response = client.post(
        f"/me/squads/{squad['id']}/items",
        json={"brand_slug": "nope", "url": PRODUCT_URL, "title": "x"},
    )
    assert response.status_code == 422


def test_assigning_an_item_counts_against_that_persons_budget(
    client, as_signed_in, squad, product
):
    cousin_id = _join(client, as_signed_in, squad)["my_member_id"]
    client.patch(f"/me/squads/{squad['id']}/me", json={"budget_personal": "20000"})
    item_id = _pin(client, squad).json()["items"][0]["id"]

    board = client.patch(
        f"/me/squads/{squad['id']}/items/{item_id}",
        json={"assigned_to": cousin_id, "note": "for the dholki"},
    ).json()

    cousin = next(member for member in board["members"] if member["id"] == cousin_id)
    assert cousin["budget_personal"] == "20000.00"
    assert cousin["planned"] == "15000.00"
    assert board["planned_total"] == "15000.00"
    assert board["items"][0]["note"] == "for the dholki"


def test_an_unassigned_pin_spends_nothing(client, as_signed_in, squad, product):
    as_signed_in(OWNER)
    board = _pin(client, squad).json()

    assert board["planned_total"] == "0"


def test_unassigning_and_clearing_a_budget(client, as_signed_in, squad, product):
    as_signed_in(OWNER)
    owner_id = squad["my_member_id"]
    item_id = _pin(client, squad).json()["items"][0]["id"]
    client.patch(f"/me/squads/{squad['id']}/items/{item_id}", json={"assigned_to": owner_id})
    client.patch(f"/me/squads/{squad['id']}/me", json={"budget_personal": "5000"})

    client.patch(f"/me/squads/{squad['id']}/items/{item_id}", json={"assigned_to": None})
    board = client.patch(f"/me/squads/{squad['id']}/me", json={"budget_personal": None}).json()

    assert board["items"][0]["assigned_to"] is None
    assert board["members"][0]["budget_personal"] is None


def test_an_item_cannot_be_assigned_outside_the_squad(client, as_signed_in, squad, product):
    as_signed_in(STRANGER)
    other = client.post(
        "/me/squads", json={"name": "Other", "event_type": "eid", "display_name": "X"}
    ).json()

    as_signed_in(OWNER)
    item_id = _pin(client, squad).json()["items"][0]["id"]
    response = client.patch(
        f"/me/squads/{squad['id']}/items/{item_id}",
        json={"assigned_to": other["my_member_id"]},
    )
    assert response.status_code == 422


def test_votes_replace_and_withdraw(client, as_signed_in, squad, product):
    as_signed_in(OWNER)
    item_id = _pin(client, squad).json()["items"][0]["id"]
    client.put(f"/me/squads/{squad['id']}/items/{item_id}/vote", json={"value": 1})
    _join(client, as_signed_in, squad)
    vote_url = f"/me/squads/{squad['id']}/items/{item_id}/vote"

    client.put(vote_url, json={"value": 1})
    board = client.put(vote_url, json={"value": -1}).json()
    assert board["items"][0]["score"] == 0
    assert board["items"][0]["my_vote"] == -1

    board = client.put(vote_url, json={"value": 0}).json()
    assert board["items"][0]["score"] == 1
    assert board["items"][0]["my_vote"] == 0


def test_comments_appear_in_order(client, as_signed_in, squad, product):
    as_signed_in(OWNER)
    item_id = _pin(client, squad).json()["items"][0]["id"]
    comments_url = f"/me/squads/{squad['id']}/items/{item_id}/comments"
    client.post(comments_url, json={"body": "Colour is perfect"})
    _join(client, as_signed_in, squad)
    board = client.post(comments_url, json={"body": "Too heavy for mehndi?"}).json()

    assert [comment["body"] for comment in board["items"][0]["comments"]] == [
        "Colour is perfect",
        "Too heavy for mehndi?",
    ]


def test_only_the_pinner_or_owner_can_remove_an_item(client, as_signed_in, squad, product):
    as_signed_in(OWNER)
    item_id = _pin(client, squad).json()["items"][0]["id"]
    _join(client, as_signed_in, squad)

    assert client.delete(f"/me/squads/{squad['id']}/items/{item_id}").status_code == 403

    as_signed_in(OWNER)
    board = client.delete(f"/me/squads/{squad['id']}/items/{item_id}").json()
    assert board["items"] == []


def test_the_invite_page_shows_the_code(client, squad):
    response = client.get(f"/i/{squad['invite_code']}")

    assert response.status_code == 200
    assert squad["invite_code"] in response.text
    assert "Ayesha&#x27;s Mehndi" in response.text


def test_an_unknown_invite_page_is_a_404(client):
    assert client.get("/i/NOTACODE").status_code == 404


def test_asset_links_name_the_app(client):
    [statement] = client.get("/.well-known/assetlinks.json").json()

    assert statement["target"]["package_name"] == "pk.brandnest.brandnest"
