# internal-docs

Password-protected internal HTML documents, encrypted with [StatiCrypt](https://github.com/robinmoisson/staticrypt) and published as a single GitHub Pages site.

## What is and isn't public
This repo is public, but it reveals nothing about the documents:
- **Content** is AES-256-GCM encrypted (600,000 PBKDF2 iterations). Only ciphertext is published.
- **Plaintext** never enters git. The `sources/` folder is gitignored and stays on the author's machine only.
- **File names** are opaque random IDs (`docs/<id>/`), so neither the repo nor the URLs reveal a document's topic.
- **Page titles** are generic; the real title lives inside the encrypted blob.
- The friendly name to ID mapping lives only in `passwords.env` (gitignored) and inside the encrypted catalog.

## Security model (read this)
- This is a shared-password gate, not per-user login. No identity, no audit log, no instant revocation.
- The encrypted files are publicly downloadable, so they can be brute-forced offline. Password strength is the only thing protecting them. Always use long random passwords from 1Password.
- To revoke access: change the document's password, rebuild, redeploy, then re-share.

## Add or update a document
1. Put or edit the plaintext at `sources/<subdir>/index.html` (local only, gitignored).
2. In `passwords.env`, add or update its `DOCS` entry: `ID|SUBDIR|Friendly Name|Description|password`.
   Generate an opaque ID with `openssl rand -hex 4` and a password from 1Password.
3. Run `./build.sh`.
4. Commit and push. Pages redeploys automatically.

## Passwords and mapping
- `passwords.env` holds `PW_CATALOG` plus the `DOCS` mapping (IDs, friendly names, passwords). It is gitignored. Keep the passwords in 1Password too.
- Never commit `passwords.env`.

## Hosting
- Pages source: `main` branch, `/docs` folder.
- `docs/robots.txt` disallows crawling; the password template sends `noindex`.
