from datetime import datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth import current_user
from app.db import db_session
from app.models import User
from app.services import reports, uploads

router = APIRouter(tags=["reports"])


class ReportOut(BaseModel):
    id: int
    text: str | None
    screenshot_url: str | None
    status: str
    points_awarded: int
    created_at: datetime


@router.post("/me/reports", response_model=ReportOut, status_code=201)
async def create_report(
    text: str = Form(""),
    screenshot: UploadFile | None = File(None),
    user: User = Depends(current_user),
    session: Session = Depends(db_session),
) -> ReportOut:
    """Send in a deal. Multipart, because the screenshot is the point — a deal
    the desk cannot see proof of is not worth queueing."""
    if not text.strip() and screenshot is None:
        raise HTTPException(
            status_code=422, detail="Add a screenshot or describe the deal."
        )
    screenshot_url = None
    if screenshot is not None:
        try:
            screenshot_url = uploads.save_screenshot(await screenshot.read())
        except uploads.UnsupportedImage as error:
            raise HTTPException(status_code=422, detail=str(error)) from error
    return _to_out(
        reports.create_report(session, user.id, text.strip(), screenshot_url)
    )


@router.get("/me/reports", response_model=list[ReportOut])
def my_reports(
    user: User = Depends(current_user), session: Session = Depends(db_session)
) -> list[ReportOut]:
    return [_to_out(report) for report in reports.reports_for_user(session, user.id)]


def _to_out(report) -> ReportOut:
    return ReportOut(
        id=report.id,
        text=report.text,
        screenshot_url=report.screenshot_url,
        status=report.status,
        points_awarded=report.points_awarded,
        created_at=report.created_at,
    )
