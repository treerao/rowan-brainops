# Slack Setup Guide (Socket Mode) for rowan-brainops

Date: 2026-02-22
Mode: Socket Mode (no public Slack webhook URL required)

## What you will get
- Slack app configured for OpenClaw Socket Mode.
- Tokens mapped into `/Users/rrao/rowan-brainops/compose/.env`.
- Working Slack DM/channel interaction after deploy.

## Fast path (recommended)
Use the App Manifest path. It sets almost everything in one action (scopes, events, socket mode, interactivity, slash command).

After manifest import, only a few manual steps remain:
1. Install/Reinstall app to workspace.
2. Create app-level token (`connections:write`) and copy it.
3. Copy bot token + app token into `.env`.
4. Invite bot to any channels you want it to reply in.

## Official references
- OpenClaw Slack docs: [https://docs.openclaw.ai/channels/slack](https://docs.openclaw.ai/channels/slack)
- Slack app dashboard: [https://api.slack.com/apps](https://api.slack.com/apps)
- Slack Socket Mode docs: [https://api.slack.com/apis/connections/socket](https://api.slack.com/apis/connections/socket)

## Step 1: Create app using manifest (fast path)
1. Open [https://api.slack.com/apps](https://api.slack.com/apps).
2. Click `Create New App` -> `From app manifest`.
3. Select your workspace.
4. Paste the full manifest below and create app.

## Step 1.5: App Manifest fragments (copy/paste)
Use these in Slack `App Manifest` for fast setup. Keep app name as `Rowan`.

### Full Manifest (paste as one block)
```yaml
display_information:
  name: Rowan
features:
  app_home:
    home_tab_enabled: false
    messages_tab_enabled: true
    messages_tab_read_only_enabled: false
  bot_user:
    display_name: Rowan
    always_online: false
  slash_commands:
    - command: /openclaw
      description: Chat with Rowan
      should_escape: false
oauth_config:
  scopes:
    bot:
      - app_mentions:read
      - chat:write
      - im:read
      - im:write
      - im:history
      - users:read
      - channels:read
      - channels:history
      - groups:read
      - groups:history
      - mpim:read
      - mpim:write
      - mpim:history
      - reactions:read
      - reactions:write
      - pins:read
      - pins:write
      - emoji:read
      - commands
      - files:read
      - files:write
settings:
  event_subscriptions:
    bot_events:
      - app_mention
      - message.im
      - message.channels
      - message.groups
      - message.mpim
      - reaction_added
      - reaction_removed
      - pin_added
      - pin_removed
  interactivity:
    is_enabled: true
  org_deploy_enabled: false
  socket_mode_enabled: true
  token_rotation_enabled: false
```

### Optional: paste nested fragments into an existing manifest
These are intentionally indented for direct drop-in under existing parent keys.

### Fragment A: Core app + Socket Mode + bot user
```yaml
display_information:
  name: Rowan
features:
  bot_user:
    display_name: Rowan
    always_online: false
settings:
  socket_mode_enabled: true
  org_deploy_enabled: false
  token_rotation_enabled: false
```

### Fragment B: OAuth scopes
```yaml
oauth_config:
  scopes:
    bot:
      - app_mentions:read
      - chat:write
      - channels:history
      - channels:read
      - groups:history
      - im:history
      - mpim:history
      - users:read
      - reactions:read
      - reactions:write
      - pins:read
      - pins:write
      - emoji:read
      - files:read
      - files:write
      - commands
      - assistant:write
```

### Fragment C: Event subscriptions (bot events)
```yaml
settings:
  event_subscriptions:
    bot_events:
      - app_mention
      - message.channels
      - message.groups
      - message.im
      - message.mpim
      - reaction_added
      - reaction_removed
      - member_joined_channel
      - member_left_channel
      - channel_rename
      - pin_added
      - pin_removed
```

### Fragment D: Optional slash command
```yaml
features:
  slash_commands:
    - command: /openclaw
      description: Chat with Rowan
      should_escape: false
```

### Fragment E: App-level token scope (do this in UI)
App-level tokens are not fully declared in manifest for all flows; create in UI:
- `connections:write` (required for Socket Mode)

## Step 2: Install app and generate app token
1. Open `Install App` (or `OAuth & Permissions`) and click `Install/Reinstall to Workspace`.
2. Open `Basic Information` -> `App-Level Tokens` -> `Generate Token and Scopes`.
3. Add scope: `connections:write`.
4. Copy the App Token (`xapp-...`).

Paste into:
- `SLACK_APP_TOKEN=` in `/Users/rrao/rowan-brainops/compose/.env`

## Step 3: Copy bot token
1. Open `OAuth & Permissions`.
2. Copy `Bot User OAuth Token` (`xoxb-...`).

Paste into:
- `SLACK_BOT_TOKEN=` in `/Users/rrao/rowan-brainops/compose/.env`

## Step 4: Update local env and deploy
1. Edit `/Users/rrao/rowan-brainops/compose/.env`:
- `SLACK_APP_TOKEN=xapp-...`
- `SLACK_BOT_TOKEN=xoxb-...`

2. Deploy:
- `cd /Users/rrao/rowan-brainops`
- `./scripts/deploy-up.sh`
- `./scripts/deploy-status.sh`

## Step 5: Invite bot to channels (if channel replies needed)
In each target channel:
- `/invite @Rowan`

## Step 6: Verify in Slack
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
  - Reinstall app if manifest/scopes changed.
- DM pairing prompt flow issues:
  - Confirm OpenClaw Slack mode is socket and channel policies are intended.

## Security hygiene
- Keep `.env` local-only and untracked.
- Rotate both Slack tokens if ever exposed.
- Never paste raw tokens in chat or docs.
