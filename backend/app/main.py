from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.admin import routes as admin
from app.api import (
    brands,
    invites,
    me,
    offers,
    points,
    products,
    reports,
    sales,
    search,
    squads,
    watches,
)
from app.config import settings
from app.db import engine

app = FastAPI(title="BrandNest API")

app.include_router(brands.router)
app.include_router(offers.router)
app.include_router(sales.router)
app.include_router(me.router)
app.include_router(points.router)
app.include_router(products.router)
app.include_router(reports.router)
app.include_router(search.router)
app.include_router(squads.router)
app.include_router(invites.router)
app.include_router(watches.router)
app.include_router(admin.router)

# Deal screenshots (US-14). Served straight off the volume — the desk needs to
# see them, and the URLs are unguessable rather than access-controlled.
Path(settings.uploads_dir).mkdir(parents=True, exist_ok=True)
app.mount(
    settings.uploads_url_path,
    StaticFiles(directory=settings.uploads_dir),
    name="uploads",
)


@app.get("/health")
def health() -> dict:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"status": "ok", "db": "ok"}
