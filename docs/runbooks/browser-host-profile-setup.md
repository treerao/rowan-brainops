# Browser Setup (Host Chrome, Dedicated Rowan Profile)

Date: 2026-02-22  
Status: Recommended fast path for interactive browser logins

## Goal
Use host Chrome for browser tasks, but isolate Rowan from your personal browser profile.

This gives you:
- easier interactive logins/MFA on host
- clear boundary for Rowan browser state
- no coupling to your daily Chrome profile

## Profile location
- Default isolated profile root:
  - `/Users/rrao/rowan-runtime/chrome-profile`

Treat this directory as sensitive runtime state (cookies/session tokens).

## 1) Launch isolated Rowan Chrome profile

From `/Users/rrao/rowan-brainops`:

```bash
./scripts/browser-open-profile.sh
```

Optional custom path/profile name:

```bash
./scripts/browser-open-profile.sh /Users/rrao/rowan-runtime/chrome-profile Rowan
```

## 2) Install/enable OpenClaw browser extension in this profile

Preferred trusted path (host CLI-managed files, not Chrome Store random install):

```bash
openclaw browser extension install
openclaw browser extension path
```

Then in the isolated Chrome window:
1. Open `chrome://extensions`.
2. Enable Developer mode.
3. Load unpacked from the path returned above (typically `~/.openclaw/browser/chrome-extension`).
4. Ensure OpenClaw/Replay extension is enabled in this profile only.
5. Open the extension and confirm it is active.
6. Keep this profile as the Rowan automation profile.

Do not install/log in through your personal profile for Rowan tasks.

## 3) Pair this browser node to Rowan

From Slack or OpenClaw workflow, initiate pairing.
When prompted in browser, approve pairing from this isolated profile.

If pairing appears stale, re-run pairing and approve again.

## 4) Perform initial site logins

In this isolated profile:
1. Log in to required target sites.
2. Complete any MFA prompts.
3. Verify the extension remains attached after login.

## 5) Validate end-to-end

Run a browser-needed task in OpenClaw and confirm:
- node appears paired/online
- authenticated page access works
- replay/headless flow succeeds

## 6) Operational notes

- Back up profile state as part of runtime backup strategy (`rowan-runtime`), not git.
- If login state breaks, reopen isolated profile and re-auth there.
- For future stronger isolation, move to dedicated browser-worker container role.
