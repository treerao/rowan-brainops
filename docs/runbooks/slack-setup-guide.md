# Slack Setup Guide (Socket Mode) for rowan-brainops

Date: 2026-02-22
Mode: Socket Mode (no public Slack webhook URL required)

## What you will get
- Slack app configured for OpenClaw Socket Mode.
- Tokens mapped into `/Users/rrao/rowan-brainops/compose/.env`.
- Working Slack DM/channel interaction after deploy.

## Official references
- OpenClaw Slack docs: [https://docs.openclaw.ai/channels/slack](https://docs.openclaw.ai/channels/slack)
- Slack app dashboard: [https://api.slack.com/apps](https://api.slack.com/apps)
- Slack Socket Mode docs: [https://api.slack.com/apis/connections/socket](https://api.slack.com/apis/connections/socket)

## Step 1: Create Slack app
1. Open [https://api.slack.com/apps](https://api.slack.com/apps).
2. Click `Create New App` -> `From scratch`.
3. Name: `Rowan` (or your preferred app name).
4. Pick your Slack workspace.

## Step 2: Enable Socket Mode and create app token
1. In app settings, open `Socket Mode`.
2. Toggle `Enable Socket Mode` on.
3. Open `Basic Information` -> `App-Level Tokens` -> `Generate Token and Scopes`.
4. Add scope: `connections:write`.
5. Copy the App Token (`xapp-...`).

Paste into:
- `SLACK_APP_TOKEN=` in `/Users/rrao/rowan-brainops/compose/.env`

## Step 3: Configure bot scopes
1. Open `OAuth & Permissions`.
2. Under `Bot Token Scopes`, add at least:
- `app_mentions:read`
- `chat:write`
- `channels:history`
- `channels:read`
- `groups:history`
- `im:history`
- `mpim:history`
- `users:read`
- `reactions:read`
- `reactions:write`
- `pins:read`
- `pins:write`
- `emoji:read`
- `files:read`
- `files:write`
- `commands`
- `assistant:write`

Notes:
- These align with current OpenClaw Slack guidance and manifest examples.
- If you do not use some capabilities immediately, you can trim later.

## Step 4: Install app and copy bot token
1. In `OAuth & Permissions`, click `Install to Workspace`.
2. Approve requested scopes.
3. Copy `Bot User OAuth Token` (`xoxb-...`).

Paste into:
- `SLACK_BOT_TOKEN=` in `/Users/rrao/rowan-brainops/compose/.env`

## Step 5: Subscribe bot events
1. Open `Event Subscriptions`.
2. Enable events.
3. Add bot events:
- `app_mention`
- `message.channels`
- `message.groups`
- `message.im`
- `message.mpim`
- `reaction_added`
- `reaction_removed`
- `member_joined_channel`
- `member_left_channel`
- `channel_rename`
- `pin_added`
- `pin_removed`

4. Open `App Home` and enable `Messages Tab` (for DM flows).

## Step 6: Add slash command (optional)
If you want slash command behavior:
1. Open `Slash Commands`.
2. Create `/openclaw` (or your preferred command).
3. Socket Mode does not require public Request URL for this path.

## Step 7: Update local env and deploy
1. Edit `/Users/rrao/rowan-brainops/compose/.env`:
- `SLACK_APP_TOKEN=xapp-...`
- `SLACK_BOT_TOKEN=xoxb-...`

2. Deploy:
- `cd /Users/rrao/rowan-brainops`
- `./scripts/deploy-up.sh`
- `./scripts/deploy-status.sh`

## Step 8: Verify in Slack
1. DM the app with a simple prompt.
2. Mention the app in a channel (`@Rowan ...`).
3. Confirm replies are received.

## Fast troubleshooting
- No replies at all:
  - Recheck `SLACK_APP_TOKEN` and `SLACK_BOT_TOKEN` in `.env`.
  - Confirm Socket Mode is enabled.
  - Restart stack after token updates.
- App in workspace but no channel responses:
  - Ensure app invited to the channel.
  - Check event subscriptions and scopes.
- DM pairing prompt flow issues:
  - Confirm OpenClaw Slack mode is socket and channel policies are intended.

## Security hygiene
- Keep `.env` local-only and untracked.
- Rotate both Slack tokens if ever exposed.
- Never paste raw tokens in chat or docs.
