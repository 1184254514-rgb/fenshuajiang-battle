"""Publish verified local artifacts to the user-authorized private repository.

Uses Git's configured credential helper in memory; never prints or saves the
credential. Source commits must already be pushed. Existing assets are not
overwritten. A new release stays a draft until every checksum is verified.
"""
import argparse
import hashlib
import http.client
import json
import os
from pathlib import Path
import subprocess
import urllib.parse
import urllib.request

REPOSITORY = "1184254514-rgb/fenshuajiang-battle"
API = "https://api.github.com/repos/" + REPOSITORY


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checkout", type=Path, required=True)
    parser.add_argument("--artifacts", type=Path, required=True)
    parser.add_argument("--notes", type=Path, required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--title", required=True)
    args = parser.parse_args()

    def git(*values):
        return subprocess.check_output(
            ["git", "-C", str(args.checkout), *values], text=True
        ).strip()

    if git("remote", "get-url", "origin") != "https://github.com/" + REPOSITORY + ".git":
        raise RuntimeError("Checkout remote is not the user-authorized repository")
    head = git("rev-parse", "HEAD")
    remote_head = git("ls-remote", "origin", "refs/heads/main").split()[0]
    if head != remote_head:
        raise RuntimeError("Source HEAD has not been verified on GitHub main")
    paths = [args.artifacts / name for name in (
        "fenshuajiang-battle-windows-lan.zip",
        "fenshuajiang-battle-source.zip",
        "SHA256SUMS.txt",
    )]
    for path in paths:
        if not path.is_file():
            raise RuntimeError("Missing artifact: " + path.name)

    credential = subprocess.run(
        ["git", "-C", str(args.checkout), "credential", "fill"],
        input="protocol=https\nhost=github.com\n\n", text=True,
        capture_output=True, check=True, timeout=30,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
    )
    fields = dict(line.split("=", 1) for line in credential.stdout.splitlines() if "=" in line)
    token = fields.get("password")
    if not token:
        raise RuntimeError("Git credential helper did not provide authentication")
    headers = {
        "Authorization": "Bearer " + token,
        "User-Agent": "fsj-verified-release",
        "Accept": "application/vnd.github+json",
    }

    def api(url, payload=None, method=None):
        body = json.dumps(payload, ensure_ascii=False).encode() if payload is not None else None
        request = urllib.request.Request(
            url, data=body, headers={**headers, "Content-Type": "application/json"}, method=method
        )
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)

    releases = api(API + "/releases?per_page=100")
    release = next((item for item in releases if item["tag_name"] == args.tag), None)
    if release is None:
        release = api(API + "/releases", {
            "tag_name": args.tag, "target_commitish": head,
            "name": args.title, "body": args.notes.read_text(encoding="utf-8-sig"),
            "draft": True, "prerelease": False,
        })
    elif release.get("target_commitish") not in [head, "main"]:
        raise RuntimeError("Existing release refers to another source revision")
    upload_url = release["upload_url"].split("{", 1)[0]
    if urllib.parse.urlsplit(upload_url).hostname != "uploads.github.com":
        raise RuntimeError("Unexpected upload destination")
    existing = {item["name"]: item for item in api(release["assets_url"])}
    for path in paths:
        digest = hashlib.file_digest(path.open("rb"), "sha256").hexdigest()
        expected = "sha256:" + digest
        if path.name in existing:
            if existing[path.name].get("digest") != expected:
                raise RuntimeError("Existing asset differs; refusing overwrite: " + path.name)
            print("Already verified:", path.name, flush=True)
            continue
        url = urllib.parse.urlsplit(upload_url + "?" + urllib.parse.urlencode({"name": path.name}))
        connection = http.client.HTTPSConnection(url.hostname, timeout=180)
        connection.putrequest("POST", url.path + "?" + url.query)
        for key, value in headers.items():
            connection.putheader(key, value)
        connection.putheader("Content-Type", "application/octet-stream")
        connection.putheader("Content-Length", str(path.stat().st_size))
        connection.endheaders()
        sent = 0
        print("Uploading:", path.name, flush=True)
        with path.open("rb") as stream:
            while chunk := stream.read(1024 * 1024):
                connection.send(chunk)
                sent += len(chunk)
                if sent % (10 * 1024 * 1024) == 0:
                    print("  %d / %d MiB" % (sent // 1048576, path.stat().st_size // 1048576), flush=True)
        response = connection.getresponse()
        uploaded = json.loads(response.read())
        if response.status != 201:
            raise RuntimeError("Upload failed with HTTP %d" % response.status)
        connection.close()
        if uploaded.get("digest") != expected or uploaded.get("size") != path.stat().st_size:
            raise RuntimeError("Remote checksum/size mismatch: " + path.name)
        print("Verified SHA-256:", path.name, flush=True)
    if release.get("draft"):
        release = api(release["url"], {"draft": False, "make_latest": "true"}, method="PATCH")
    assets = api(release["assets_url"])
    result = {
        "url": release["html_url"], "source_commit": head, "tag": args.tag,
        "assets": [{key: item.get(key) for key in ("name", "size", "digest", "browser_download_url")} for item in assets],
    }
    (args.artifacts / "release-info.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Published and verified:", release["html_url"], flush=True)


if __name__ == "__main__":
    main()
