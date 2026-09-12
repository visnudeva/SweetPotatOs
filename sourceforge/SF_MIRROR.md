# Cloudflare Worker: sf-mirror.net → GitHub overlay

Second Harvest ships a dead fallback:

```text
Server = https://sf-mirror.net/projects/sweetpotatos/repo
Server = https://sf-mirror.net/projects/sweetpotatos/repo/$arch
```

When SourceForge times out, pacman tries this host and **fatally** aborts if DNS fails.
Register **sf-mirror.net**, point it at Cloudflare, deploy this worker — then plain
`sudo spo-upgrade` works again with no user instructions.

## Setup

1. Register `sf-mirror.net` (currently unregistered).
2. Add the zone to Cloudflare (free plan is enough).
3. In the zone: Workers & Pages → Create → paste `sourceforge/sf-mirror-worker.js`.
4. Add routes:
   - `sf-mirror.net/*`
   - `www.sf-mirror.net/*` (optional)
5. DNS: proxied AAAA `100::` or CNAME to `workers.dev` per Cloudflare docs for worker-only domains.

## Paths served

| Request | Upstream |
|---------|----------|
| `/projects/sweetpotatos/repo/<file>` | GitHub Release `pacman-repo/<file>` |
| `/projects/sweetpotatos/repo/x86_64/<file>` | same (flat release layout) |

After the first successful upgrade, new `spo-upgrade` migrates Server lines to GitHub and drops `sf-mirror.net`.
