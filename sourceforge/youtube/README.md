# YouTube — Fourth Harvest screencast

Video: `/home/visnudeva/Videos/FourthHarvest.mp4`  
Channel: https://www.youtube.com/@SweetPotat-Os  
Metadata: `fourth-harvest.meta.json`

## Upload (OAuth API)

1. Google Cloud Console → enable **YouTube Data API v3**
2. Create OAuth client (Desktop app), download JSON as `client_secrets.json` here
3. Run:

```bash
/tmp/ytupload-venv/bin/python upload_fourth_harvest.py
```

Approve access as the Google account that owns **SweetPotatOs**.

## Upload (Studio UI)

1. Open Studio upload for the channel
2. Drop `FourthHarvest.mp4`
3. Paste clipboard (title + description already prepared)
