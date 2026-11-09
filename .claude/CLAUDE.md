# Global preferences

This file is shared by both machines: it lives in the `zsh-dotfiles` repository (`.claude/CLAUDE.md`), and `~/.claude/CLAUDE.md` on the MacBook and the Mac Mini is a symlink to it. **Edit `~/zsh-dotfiles/.claude/CLAUDE.md`, then commit and push**, and `git pull` in `~/zsh-dotfiles` on the other machine. An edit that isn't pushed reaches only one machine. Facts that hold on only one machine say which.

## Never hard-wrap prose to a fixed column width

When authoring or editing any prose document — Markdown, reports, notes, docs, READMEs, memory files — write each paragraph, list item, table row and blockquote line as **one continuous line**, however long it runs. Let the editor soft-wrap it.

**Why:** Michael copies this text into other buffers (email, Basecamp, chat, docs). Hard line breaks at ~80 characters survive the paste and turn into ragged, broken-looking text that has to be re-joined by hand. Hard wraps also make diffs noisier: rewording one sentence reflows the whole paragraph and shows as many changed lines instead of one.

**How to apply:**
- A paragraph = one line. No breaks inserted purely to hit a character width.
- Line breaks are still correct where they carry *meaning*: between paragraphs, between list items, table rows, code blocks, headings, and a deliberate Markdown line break (two trailing spaces or `<br>`).
- This applies to editing existing files too — if a paragraph is already hard-wrapped and being rewritten, unwrap it rather than preserving the wrapping.
- **Exceptions, where wrapping is conventional and the text isn't copy-pasted as prose:** git commit messages (72-column convention) and code comments.

## Basecamp CLI — general principles

Learned across sessions using the `basecamp` skill/CLI. These apply to any Basecamp project, not just one client.

- **The CLI authenticates as a separate "Claude Code" Basecamp identity**, not your personal login (confirm with `basecamp me`). For *any* project to be accessible, that identity must be explicitly added as a project member first (Basecamp → project → People → Add people). Before that, `basecamp projects list` simply won't show the project, and direct access (`basecamp projects show <id>`) returns a plain "Not Found" — indistinguishable from the project not existing. If a Basecamp project seems inaccessible, check membership before assuming a bad ID.
- **To find work assigned via @-mention**, check `basecamp notifications --json` (the `unreads` array) rather than hunting through cards/todos manually — mentions and assignments surface there with a direct link to the recording.
- **A card/todo's own `content` field is only the original description.** Later clarifying comments (including the @mention that prompted picking the task up) live in the comment thread — use `basecamp comments list <recording_id> --in <project>` to see the full history, not just the top-level content.
- **Image/screenshot attachments on cards are often the actual spec** — download and genuinely view them (`basecamp cards show <id> --download-attachments=<dir>`, then read the file) rather than inferring from the filename or surrounding text. Note the `=` between the flag and the directory — passing it as a separate arg doesn't parse correctly.
- **To edit a comment that contains an @mention, resend the whole comment as Markdown** with `@First.Last` (`basecamp comments update <id> "<markdown>"`). Never fetch the comment's HTML, tweak it and pass it back: the round trip mangles the `<bc-attachment>` mention into a stray chip, avatar and name on separate lines. Keep the Markdown source of anything you post in case it needs an edit, and afterwards check there's exactly one `<bc-attachment` per mention.
- **Tables need HTML, and then the whole body must be HTML.** The CLI flattens Markdown pipe tables into one paragraph of `|` text, and once a body contains any HTML it skips Markdown conversion for all of it, so `**`, `##`, `-` and `[link](url)` show up literally. Convert the entire body first (`pandoc -f markdown-smart -t html --wrap=none`) and send that. `basecamp docs update` without `--title` resets the doc's title to "Untitled", so always pass `--title`. After posting, check the saved content has no `**` or `## ` left and has the expected `<table>`/`<li>` counts. (Learned on PMD doc 10437460157, 2026-10-23.) pandoc isn't installed on the Mac Mini; there, convert with Python's `markdown` package (extensions `tables` and `fenced_code`) in a throwaway venv in the scratchpad.
- **Post a comment with `basecamp comments create <id|url> "<content>" --format html --in <project>`** (CLI 0.24.0 and later). The old `basecamp comment <id> "…"` command is gone and fails with `unknown command "comment"`. `--format html` sends the body without conversion, and `--format markdown` converts it. Pass `-` as the content to read it from stdin. For an @mention in an HTML body, write the mention tag yourself: `<bc-attachment sgid="<attachable_sgid>" content-type="application/vnd.basecamp.mention"></bc-attachment>`, with the SGID from `basecamp people pingable --jq '.data[] | select(.name == "First Last")'`. Afterwards, check the saved comment (`basecamp comments show <id> --jq '.data.content'`) has one `<bc-attachment` per mention. (Learned on JBC to-do 10325885921, 2026-11-06.)
- **`basecamp upgrade` only reports a new version; it doesn't install it.** To upgrade, download the `darwin_arm64` tarball and `checksums.txt` from the `basecamp/basecamp-cli` GitHub release (`gh release download v<version> -R basecamp/basecamp-cli -p 'basecamp_<version>_darwin_arm64.tar.gz' -p checksums.txt`), check it with `shasum -a 256 -c`, and copy the binary over `~/.local/bin/basecamp`. The Mac Mini moved from 0.7.2 to 0.24.0 on 2026-11-06. Check the MacBook's version with `basecamp --version`.
- **Put an empty paragraph, `<p><br></p>`, between top-level blocks in HTML bodies.** Basecamp shows paragraphs with no space between them, so a converted Markdown body reads as one wall of text. Michael's own posts put a spacer between every paragraph, heading, table, list and code block, but not between list items. After posting, check the saved content has one fewer spacer than it has blocks. Basecamp saves each spacer as `<p dir="auto"><br></p>`, so count with a pattern like `<p[^>]*><br></p>`. (Learned on PMD card 10476979019, 2026-11-04.)
- **When picking up a task from a card table that predates AI-assisted execution**, verify the actual intent with the user before starting even if the card text looks clear — cards written for a human to read later often omit context an agent needs, and the fastest path to a wrong deliverable is assuming the card is complete as written.

## Email: Google Workspace, not HEY

Michael's working email is **mwender@wenmarkdigital.com**, a Google Workspace account — use the Gmail connector (and Google Calendar/Drive) for anything email-related: drafting, searching threads, finding a client's address. He rarely uses HEY during working hours, so don't offer HEY drafts or refer to HEY by default, even when a HEY plugin or skill is loaded. Only use HEY when he names it. If the Gmail connector isn't available in a session, say so rather than falling back to HEY.

### Gmail drafts: no images, and every URL gets wrapped

The Gmail connector sanitizes what Claude saves with `create_draft` / `update_draft` (confirmed 2026-10-17 by reading drafts back in RAW format, so this is what's stored, not just how it's displayed):

- **Every `<img>` is removed**, whatever its attributes. Inline attachments (`inline: true`) get a random Content-ID, so the HTML can't reference them either.
- **Every URL is rewritten** to `https://www.google.com/url?q=<url>&source=gmail&ust=…&sa=E` — in `href`s, in bare text, without a scheme, inside `<code>`, and even in a plain-text-only body. Michael then has to dig the real URL out by hand.
- Edits Michael makes in the Gmail UI are **not** sanitized: images he inserts with Insert photo → Web address are stored and sent normally.

**How to apply:** when an email needs images or exact links, write the draft with a short caption line plus a placeholder where each one goes (e.g. `Before Susan signs:` then `[Image: Sam's view before Susan signs]`), host the images somewhere public, and give Michael the clean URLs **in the chat reply**, one per line, so he can paste each into Insert photo → Web address. Screenshots for emails stay at their **original captured resolution** — never scale them down or crop them to a display width; Michael picks the display size in Gmail. Don't spend tokens on base64 attachments to work around this.

## Scheduled jobs on the Mac Mini — SpinupTUI's Scheduler

To run something later and unattended (a check tomorrow morning, a recurring report), queue a **Scheduler job** instead of asking the user to remember it. Since 2026-10-28 jobs live in `~/SpinupTUI/scheduler/` on the Mac Mini. The LaunchAgent `com.spinuptui.scheduler` runs them, writes each report to `runs/<id>/`, pushes the folder to the private `mwender/spinuptui-home` repository as a backup, and pages the result through Beacon. Read `~/Projects/spinupwp-cli-dashboard/docs/scheduler.md` before your first one: it covers job kinds, schedules, the read-only defaults, and why the prompt has to stand on its own. (The old `mini-jobs` repository and its `minijob` command are retired.)

**Queue jobs only from a session on the Mac Mini.** Michael doesn't queue from the MacBook. On any other machine, tell him what you would queue instead.

```bash
~/.bun/bin/spinuptui scheduler add <id> --kind agent|codex|script|spinuptui \
  --when "YYYY-MM-DD HH:MM" | --every "weekdays 08:00" \
  --expires YYYY-MM-DD --created-by "<agent> — <project> session" \
  [--allow "Read,Grep,Glob,Bash(ssh user@host *)"] [--workdir <dir>] --body-file <file>
```

Use the full path `~/.bun/bin/spinuptui`. A plain `spinuptui` on the shell PATH is Homebrew's stable release, which has no Scheduler until 1.3.0 ships. Read results with `scheduler list`, `scheduler show <id>` and `scheduler status`. Confirm with the user before queuing anything recurring, or anything that acts rather than reports.

## Machines, the Projects folder and `sshconn`

- **The Projects folder** is `~/Dropbox/Projects` on the MacBook and `~/Projects` on the Mac Mini. GitHub is the source of truth between them, not Dropbox: commit and push before switching machines. Workspace conventions are in its root `AGENTS.md`; machine facts about the Mini (access, tooling, quirks) are in `headless-mac-mini/AGENTS.md`.
- **The Mac Mini** is `macmini@macs-mac-mini` over Tailscale (key auth, works with `BatchMode=yes`); the MacBook is `mwender@macbook-pro`. Prefer the Tailscale names to `.local` or LAN addresses, which change.
- **`sshconn <name>` is Michael's SSH wrapper on the MacBook** (`~/bin/sshconn`). It looks up `<name>` in `~/.connections`, a plain CSV (`name,user,host,port`, port optional, default 22, mode 0600, no secrets), and runs `ssh -p <port> <user>@<host>`. From an agent, resolve the line yourself and call `ssh` directly, because `sshconn`'s modes prompt or open an interactive shell: `L=$(grep '^name,' ~/.connections)`, then `ssh -o BatchMode=yes -p "${port:-22}" "$user@$host" '<cmd>'`. Exact name match only; if a name has two lines, refuse, as `sshconn` does. A server listed there is still subject to the rules in the next section. The Mini has no `sshconn`, and its own `~/.connections` is a short, unrelated list.

## SSH to Michael's servers: ask, don't probe

**Never guess SSH usernames, hostnames or keys, and never retry a failed SSH connection to Michael's servers.** His servers run fail2ban, and repeated failed public-key attempts ban the source IP. On 2026-10-20 a session tried several guessed users (`mwender`, `wenmark`, `root`, `aspire`, `thepearlataspire` before its key was added) against web1.hollingsworthcos.com (165.227.180.161). Port 22 then refused every connection from the office IP, which locked out both the Mac Mini and the MacBook. Clearing it took a support request to SpinupWP.

**How to apply:**
- **For a SpinupWP site, resolve the target with SpinupTUI first:** `~/.bun/bin/spinuptui ssh <domain>` prints the site user, server IP and port as JSON. It's installed through bun, which isn't on non-interactive shells' PATH, so use the full path. Source and docs: `~/Projects/spinupwp-cli-dashboard`. The command runs one live connectivity probe, which counts as your one attempt, so don't follow it with a manual `ssh` if the probe failed. For read-only commands, `spinuptui ssh-exec <domain> -- '<command>'` resolves the target and refuses anything that writes.
- If the SSH user and host aren't written down (in `~/.ssh/config`, the project's docs, SpinupTUI, or by Michael in this conversation), **ask him** for the exact `user@host`. Don't try candidates.
- **Connect by the server IP, not the site's domain.** The Mini's `known_hosts` stores host keys by IP, so with `BatchMode` a domain name fails with `Host key verification failed`. The SpinupWP site user is often not the domain (thepearlataspire.com's user is `thepearl`).
- **One attempt.** If it fails with `Permission denied` or `Connection refused`, stop and report the exact error, the user@host tried, and the fingerprint of the key the Mini offers. Michael will check the key is on that site user. Don't retry until he says it's fixed, and then try once.
- SpinupWP keys are per **site user**. A key that works for one site's user doesn't work for another site on the same server.
- Public, read-only routes (the WP REST API, `curl`) are fine to use first. They don't count against fail2ban.

## SpinupWP sites: pushing to `main` deploys to production

For nearly every site Michael hosts on SpinupWP, the site has **Push-to-Deploy** turned on: a push to the repo's `main` branch fires a webhook, and SpinupWP pulls `main` onto production and runs the site's deploy script. For Bedrock sites that script is typically `composer install -o --no-dev` plus any build steps. Changing production code means committing to the repo and pushing `main`. There's no separate copy step, and production's `composer.json` and `composer.lock` should always match `main`.

**How to apply:** treat `git push origin main` on a SpinupWP-hosted site as a production deploy. Do the work on a branch, and push or merge to `main` only when Michael has approved the change going live. Take a database backup first when the change runs migrations, such as a major plugin upgrade. Never push `main` just to "save" work in progress. If you're unsure whether a site uses Push-to-Deploy, ask; the SpinupWP site's Git panel shows it.

## SpinupWP sites: set PHP limits in the dashboard, not in code

PHP settings for a SpinupWP site — memory limit, upload size, execution time — are set in the SpinupWP dashboard (site → **PHP** tab), and that's the only reliable place. SpinupWP writes them into the site's PHP-FPM pool as `php_admin_value`, which blocks `ini_set()`, so `WP_MEMORY_LIMIT` / `WP_MAX_MEMORY_LIMIT` in `wp-config.php` or Bedrock's `config/application.php` silently do nothing. Confirmed 2026-10-19 on wenmarkdigital.com: at the untouched 128M default, `ini_set` could still raise the limit; once the PHP tab was set to 512M, `ini_set('memory_limit', …)` returned false. See https://spinupwp.com/doc/how-to-change-php-settings/.

**How to apply:** when a SpinupWP site needs more memory (e.g. "Allowed memory size … exhausted" fatals in `~/logs/debug.log`), ask Michael to raise it in the PHP tab, or note it for him. Don't add memory constants to the site's code. To check the effective value, request a temporary PHP file in the webroot that echoes `ini_get('memory_limit')`, then delete it. The CLI value from `wp eval` comes from a different config and doesn't reflect the site's FPM pool.

## Local copies: load missing media from production with SpinupTUI

When a local WordPress copy has the database but not the media library, don't hand-write web-server rules to fetch images. SpinupTUI (`spinuptui`, source in `~/Projects/spinupwp-cli-dashboard`) has a **production media fallback**: in the TUI, link the site to its local copy (`L`), then press `m`. That writes a self-contained mu-plugin, `spinup-media-fallback.php`, into `web/app/mu-plugins/` (Bedrock) or `wp-content/mu-plugins/`. The plugin rewrites any uploads URL whose file is missing locally to the same path on production, and it turns itself off on the production domain. Press `m` again to remove it, or `u` to update it. Details: `docs/production-media-fallback.md` in that repo.

**How to apply:** suggest it whenever a local copy shows broken images after a DB sync. There's no non-interactive CLI subcommand for it, so ask Michael to press the keys, or drive the TUI with the pilotty skill if he'd like that. Make sure the plugin file is gitignored in the site repo (a `mu-plugins/*/` rule only ignores folders, not single files).

## DNS checks: the office network intercepts port 53, so use DNS over HTTPS

On the office network (gateway `192.168.4.1`), every plain DNS query is intercepted and answered from a cache, whatever server you name. `dig @192.0.2.1`, an address with no server, still gets an answer, and `dig @<authoritative nameserver>` can return a stale record whose TTL counts down. The answering resolvers are AWS addresses, so the cause is most likely the router's DNS filtering (an eero, judging by the 192.168.4.x range, with eero Plus/Secure) and not the ISP. It applies to both machines while they're on that network, and not to the MacBook elsewhere. Found 2026-11-09 during the wenmarkdigital.com move from Route 53 to Cloudflare, where it made a proxied record look DNS-only.

**How to apply:** for propagation checks, or to see what an authoritative server is serving right now, query over HTTPS instead of `dig`: `curl -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=<host>&type=<T>'`, or `https://dns.google/resolve?name=<host>&type=<T>`, whose `Comment` field names the authoritative server it asked. Treat a plain `dig` answer as possibly cached.

## Billing rate

Michael's hourly rate is **$125/hr** (confirmed 2026-11-02). Use it when estimating or quoting client work, and show quotes as hours × $125 unless he gives a fixed price.
