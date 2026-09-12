/**
 * sf-mirror.net — pacman bootstrap mirror for Second Harvest SweetPotatOs.
 * Proxies to the GitHub Release overlay so dead DNS no longer aborts pacman -Sy.
 *
 * Deploy on Cloudflare Workers; see SF_MIRROR.md.
 */
const UPSTREAM =
  "https://github.com/visnudeva/SweetPotatOs/releases/download/pacman-repo";

const PREFIXES = [
  "/projects/sweetpotatos/repo/x86_64/",
  "/projects/sweetpotatos/repo/",
];

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", { status: 405 });
    }

    let file = null;
    for (const prefix of PREFIXES) {
      if (url.pathname.startsWith(prefix)) {
        file = url.pathname.slice(prefix.length);
        break;
      }
    }
    if (!file || file.includes("..") || file.includes("/")) {
      return new Response("Not Found", { status: 404 });
    }

    const upstream = `${UPSTREAM}/${file}`;
    const res = await fetch(upstream, {
      method: request.method,
      redirect: "follow",
      headers: {
        "User-Agent": "SweetPotatOs-sf-mirror-worker",
        Accept: request.headers.get("Accept") || "*/*",
      },
    });

    const out = new Response(res.body, res);
    out.headers.set("Cache-Control", "public, max-age=300");
    out.headers.set("X-SweetPotatOs-Mirror", "sf-mirror.net");
    return out;
  },
};
