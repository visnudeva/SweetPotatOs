#!/usr/bin/env python3
"""Upload Fourth Harvest screencast to the SweetPotatOs YouTube channel."""
from __future__ import annotations

import json
import sys
from pathlib import Path

from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials

ROOT = Path(__file__).resolve().parent
SCOPES = [
    "https://www.googleapis.com/auth/youtube.upload",
    "https://www.googleapis.com/auth/youtube",
]
VIDEO = Path("/home/visnudeva/Videos/FourthHarvest.mp4")
META = ROOT / "fourth-harvest.meta.json"
TOKEN = ROOT / "token.json"


def find_secrets() -> Path:
    candidates = [
        ROOT / "client_secrets.json",
        ROOT / "client_secret.json",
        *sorted(Path.home().joinpath("Downloads").glob("client_secret*.json")),
    ]
    for p in candidates:
        if p.is_file():
            return p
    raise SystemExit(
        "Missing client_secrets.json. Enable YouTube Data API v3, create an OAuth "
        "Desktop client, download it into Downloads/ or this folder as "
        "client_secrets.json, then re-run."
    )


def creds(secrets: Path) -> Credentials:
    c = None
    if TOKEN.exists():
        c = Credentials.from_authorized_user_file(str(TOKEN), SCOPES)
    if c and c.valid:
        return c
    if c and c.expired and c.refresh_token:
        c.refresh(Request())
        TOKEN.write_text(c.to_json())
        return c
    flow = InstalledAppFlow.from_client_secrets_file(str(secrets), SCOPES)
    c = flow.run_local_server(port=8080, prompt="consent", open_browser=True)
    TOKEN.write_text(c.to_json())
    return c


def main() -> int:
    secrets = find_secrets()
    meta = json.loads(META.read_text())
    youtube = build("youtube", "v3", credentials=creds(secrets))
    body = {
        "snippet": {
            "title": meta["title"],
            "description": meta["description"],
            "tags": meta.get("tags", []),
            "categoryId": str(meta.get("categoryId", "28")),
            "defaultLanguage": meta.get("language", "en"),
            "defaultAudioLanguage": meta.get("language", "en"),
        },
        "status": {
            "privacyStatus": meta.get("privacyStatus", "public"),
            "selfDeclaredMadeForKids": bool(meta.get("madeForKids", False)),
            "embeddable": bool(meta.get("embeddable", True)),
            "license": meta.get("license", "youtube"),
            "publicStatsViewable": bool(meta.get("publicStatsViewable", True)),
        },
    }
    if meta.get("recordingDate"):
        body["recordingDetails"] = {"recordingDate": meta["recordingDate"]}

    media = MediaFileUpload(str(VIDEO), chunksize=8 * 1024 * 1024, resumable=True, mimetype="video/mp4")
    request = youtube.videos().insert(part=",".join(body.keys()), body=body, media_body=media)
    response = None
    print(f"Uploading {VIDEO} ({VIDEO.stat().st_size} bytes)…", flush=True)
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"  {int(status.progress() * 100)}%", flush=True)
    vid = response["id"]
    url = f"https://www.youtube.com/watch?v={vid}"
    print(url, flush=True)
    (ROOT / "last-upload.json").write_text(
        json.dumps({"id": vid, "url": url, "title": meta["title"]}, indent=2) + "\n"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
