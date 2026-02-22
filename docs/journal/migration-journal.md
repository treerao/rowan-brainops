# Migration Journal

Purpose: preserve decisions, rationale, and conversation-driven context for this migration.

## Journal rules
- Log entries are chronological and dated.
- Each decision records rationale and implications.
- Open questions remain explicit until resolved.

## Entry template
- Date:
- Context:
- Decision:
- Rationale:
- Tradeoffs:
- Follow-ups:

## Entries

### 2026-02-22
- Context: Need to migrate from legacy non-containerized ClawDBot/OpenClaw host to a new Mac mini used both personally and for service hosting.
- Decision: Establish dedicated migration repo with runbooks, compose baseline, and architecture notes.
- Rationale: Replace ad-hoc setup with explicit, repeatable operations.
- Tradeoffs: More upfront design effort.
- Follow-ups: Collect old-host inventory and map to destination runtime.

### 2026-02-22
- Context: Repo positioning discussed (public OSS style vs strong personal share).
- Decision: Keep polished personal-share style with disciplined docs, without heavy OSS governance overhead.
- Rationale: Maximize clarity and speed while preserving option to grow later.
- Tradeoffs: Fewer formal contribution/security artifacts in early phase.
- Follow-ups: Maintain high documentation quality and clear structure.

### 2026-02-22
- Context: Networking/access strategy for containerized runtime.
- Decision: Prefer Cloudflare Access + Tunnel path and avoid publishing internal app port to host by default.
- Rationale: Reduce attack surface and centralize access control.
- Tradeoffs: Increased dependency on cloud tunnel/auth availability.
- Follow-ups: Ensure tunnel credentials and break-glass procedures are documented.

### 2026-02-22
- Context: Need authenticated browsing for tasks and Claw browser replay workflows.
- Decision: Plan for dedicated stateful browser automation profile in containerized workflow (not personal Chrome profile).
- Rationale: Isolate automation auth state and improve portability.
- Tradeoffs: Additional operational complexity for session refresh/MFA.
- Follow-ups: Add browser-worker service design and re-auth runbook.

### 2026-02-22
- Context: Old-host export summary received with blockers/risks.
- Decision: Convert export summary into a concrete cutover checklist with blocker-first sequencing.
- Rationale: Ensure execution readiness and rollback clarity.
- Tradeoffs: Requires complete secret re-provisioning before cutover.
- Follow-ups: Ingest `.tgz` contents and produce exact env contract + test plan.

### 2026-02-22
- Context: User proposed brain-first strategy (migrate core brain; treat old host as requirement signal).
- Decision: Adopt brain-first migration model with three tiers: core brain, compatibility bridge, intentional re-architecture.
- Rationale: Preserve continuity while avoiding legacy lock-in.
- Tradeoffs: Some integrations may temporarily lag until Tier 2/3.
- Follow-ups: Build decision matrix per legacy feature and classify preserve/rebuild/defer/retire.

## Open questions
- Which browser replay-dependent flows are truly cutover-critical versus deferrable?
- Should browser-worker be Tier 2 or Tier 3 for first migration window?
- Which legacy cron/launch tasks must remain in immediate scope?

## Change log for journal maintenance
- 2026-02-22: Initialized journal and backfilled major decisions from active planning conversation.

### 2026-02-22
- Context: Ingested provided archive `/Users/rrao/Downloads/rowan-migration-2026-02-21.tgz`.
- Decision: Use archive as requirements signal and generate brain-first feature matrix + env contract docs.
- Rationale: Move from assumptions to concrete migration plan based on real host artifacts.
- Tradeoffs: Export quality is partial (`state-inventory.md` sparse, launchd/systemd manifest empty).
- Follow-ups: Fill missing state-path inventory manually from old host if needed.

### 2026-02-22
- Context: Parsed `manifests/openclaw.json` and found plaintext tokens/keys.
- Decision: Treat archive as sensitive, avoid propagating values, and require credential rotation during cutover.
- Rationale: Minimize blast radius from existing secret exposure in exported artifact.
- Tradeoffs: Additional credential rotation work before go-live.
- Follow-ups: Add rotation checklist and execute secret replacement before traffic flip.

### 2026-02-22
- Context: Archive ingest revealed plaintext secrets in exported config.
- Decision: Add an explicit secret-rotation runbook with ordered sequence and validation gates.
- Rationale: Reduce risk of credential reuse/exposure during migration.
- Tradeoffs: Additional migration work and coordination time.
- Follow-ups: Execute rotation checklist before traffic flip and log evidence.

### 2026-02-22
- Context: Clarification that workspace repo is backed up to GitHub and represents most core brain content.
- Decision: Define explicit three-layer brain boundary (workspace content, runtime state, secrets).
- Rationale: Prevent false confidence that git backup alone equals full operational recovery.
- Tradeoffs: Requires maintaining multiple backup/recovery paths.
- Follow-ups: Validate each layer during first recovery rehearsal.

### 2026-02-22
- Context: Discussed whether containerization supports multiple OpenClaw instances on the same host.
- Decision: Prefer role-based multi-instance layout over staging-focused layout.
- Rationale: Different operational roles (core, browser-heavy, ops/admin) map better to real usage patterns.
- Tradeoffs: More per-instance config/secrets/monitoring overhead.
- Follow-ups: Draft compose role pattern with isolated volumes, env, and ingress per role.

### 2026-02-22
- Context: Reviewed host hardware capacity for realistic expectations.
- Decision: Target 3 role-based instances as primary plan (core + browser + ops), with optional 4th only if workloads remain light.
- Rationale: 24 GB RAM and browser-heavy tasks make memory the first scaling constraint.
- Tradeoffs: Must enforce concurrency and memory discipline to avoid latency/regressions.
- Follow-ups: Set per-role resource budgets and max concurrency defaults.

### 2026-02-22
- Context: Clarified likely bottleneck order on this Mac mini.
- Decision: Prioritize constraints as memory first, compute bursts second, storage growth third.
- Rationale: Browser automation and concurrent agent/tool runs are memory-intensive; disk currently has ample headroom.
- Tradeoffs: Requires proactive limits and retention policies.
- Follow-ups: Add memory/CPU/storage guardrails to operational checklist.

### 2026-02-22
- Context: Need a practical secrets process that avoids terminal entry and shell-history leakage.
- Decision: Adopt GUI-first secrets workflow (vault UI -> local gitignored env -> Docker Desktop restarts).
- Rationale: Better operational hygiene with minimal complexity for personal hosting.
- Tradeoffs: Manual copy step remains; requires discipline and periodic audits.
- Follow-ups: Implement vault key set and run one full rotation rehearsal.

### 2026-02-22
- Context: Strategy and requirements are evolving quickly as migration options are explored.
- Decision: Prioritize high-fidelity capture in the journal now, then periodically consolidate into cleaner, distinctive final patterns/use-case outputs.
- Rationale: Preserves decision context and avoids losing important signal during rapid iteration.
- Tradeoffs: Temporary document sprawl and some duplication until consolidation passes.
- Follow-ups: Add periodic "consolidation checkpoints" that convert journal signal into stable runbooks and reference outputs.

### 2026-02-22
- Context: Cloned private reference workspace repo `treerao/rowan` for structural inspection.
- Decision: Use real workspace structure to guide deployment design; include dedicated web-serving boundary and avoid serving full repo tree.
- Rationale: Prevent accidental exposure of sensitive/private artifacts while preserving core brain continuity.
- Tradeoffs: Requires explicit allowlist and extra service config for content serving.
- Follow-ups: Build compose with OpenClaw + rowan-web + cloudflared and path allowlist defaults.

### 2026-02-22
- Context: User requested full build-out so only `.env` editing plus Cloudflare/Slack portal admin remains.
- Decision: Implement single-instance deploy baseline with `openclaw`, `rowan-web` (allowlisted Express server), and `cloudflared` services.
- Rationale: Move from planning artifacts to an executable deployment skeleton tied to the actual `treerao/rowan` workspace structure.
- Tradeoffs: Some OpenClaw provider/channel behavior still depends on exact runtime config compatibility in chosen image.
- Follow-ups: Fill `.env`, run deploy, and verify Slack + Cloudflare end-to-end.

### 2026-02-22
- Context: Executed local prep for newly implemented single-instance stack.
- Decision: Initialize runtime directories and bootstrap private workspace clone before secret provisioning.
- Rationale: Ensure filesystem and workspace prerequisites are ready so deployment is blocked only on credentials/portal setup.
- Tradeoffs: None significant; stack launch still gated on valid secret values.
- Follow-ups: Fill `compose/.env`, configure Cloudflare ingress + Access and Slack tokens, then run deploy-up and verification.

### 2026-02-22
- Context: Requested a ready-to-use Slack setup guide with links.
- Decision: Added step-by-step Socket Mode runbook aligned to current OpenClaw docs and local `.env` contract.
- Rationale: Minimize setup ambiguity and keep portal work deterministic.
- Tradeoffs: Initial scope list is broad for compatibility; can be tightened after baseline validation.
- Follow-ups: Execute guide, validate DM + channel flows, then prune unneeded Slack scopes.

### 2026-02-22
- Context: First live deployment attempted; Docker Desktop unavailable and switched to Colima runtime.
- Decision: Start Colima, set Docker context to `colima`, and deploy stack there.
- Rationale: Preserve momentum without requiring Docker Desktop.
- Tradeoffs: Additional local runtime layer and image pull time on first start.
- Follow-ups: Document Colima as supported local runtime option.

### 2026-02-22
- Context: `rowan-openclaw` crash-looped after initial deploy.
- Decision: Change startup command from `openclaw gateway ...` to image-native `node openclaw.mjs gateway --allow-unconfigured --port ...`.
- Rationale: OpenClaw image does not ship a global `openclaw` binary in PATH for that command style.
- Tradeoffs: Compose command now tied to current image command contract.
- Follow-ups: Re-check command if image major version changes.

### 2026-02-22
- Context: OpenClaw emitted path permission errors and unstable health behavior.
- Decision: Stop injecting full `.env` into all services; pass explicit env keys only. Correct OpenClaw config volume path to `/home/node/.openclaw`.
- Rationale: Prevent accidental env collisions and align with container runtime user paths.
- Tradeoffs: Slightly more verbose compose environment section.
- Follow-ups: Keep per-service env minimal and explicit.

### 2026-02-22
- Context: Slack pairing approved, but first replies failed with provider auth errors.
- Decision: Diagnose provider/model path and correct provider key mapping in `.env`.
- Rationale: Runtime attempted OpenAI models with a non-OpenAI key due swapped env values.
- Tradeoffs: Required key correction and restart cycle.
- Follow-ups: Rotate provider keys and add key-prefix sanity check before future deploys.

### 2026-02-22
- Context: Slack connection healthy but replies landed in threads by default.
- Decision: Set Slack reply behavior directly in OpenClaw via config so operational behavior matches desired UX.
- Rationale: Keep interaction mode aligned to user expectation (main chat flow).
- Tradeoffs: Behavior is app-config dependent and should be captured as baseline.
- Follow-ups: Persist reply mode in operational checklist and verify after upgrades.

### 2026-02-22
- Context: End-to-end status check after fixes.
- Decision: Accept baseline as working: Slack socket connected, pairing approved, message flow functioning.
- Rationale: Meets immediate objective for containerized single-instance operations.
- Tradeoffs: Hardening tasks remain (token handling, role profiles, backup rehearsal).
- Follow-ups: Execute hardening pass and commit stable baseline.

### 2026-02-22
- Context: Cloudflare setup completed with new tunnel; external endpoint confirmed working.
- Decision: Keep new Rowan on dashboard-managed tunnel model and keep old Rowan behavior separate.
- Rationale: Cleaner management boundary and lower confusion from mixed tunnel modes.
- Tradeoffs: Requires explicit Access and route verification in updated UI.
- Follow-ups: Harden tunnel credential handling and verify Access challenge behavior in private browser sessions.

### 2026-02-22
- Context: Running workload appeared stalled during a live request.
- Decision: Diagnose container activity and logs; identified session write permission issues and fixed host-mounted path permissions.
- Rationale: Confirmed issue was runtime persistence, not connectivity.
- Tradeoffs: Temporary broad permissions applied to restore operation quickly.
- Follow-ups: tighten filesystem permissions with least-privilege mapping after stability window.

### 2026-02-22
- Context: OpenClaw version lag and provider/auth issues during Slack use.
- Decision: Upgrade runtime image to `ghcr.io/openclaw/openclaw:2026.2.21` and correct provider key mapping/model defaults.
- Rationale: Restore stable response path and align to newer runtime.
- Tradeoffs: Still tag-based pinning, not digest pinning.
- Follow-ups: move to digest pinning and add pre-upgrade provenance/scan checks.

### 2026-02-22
- Context: Need alignment with standard OpenClaw workspace semantics.
- Decision: Switch OpenClaw workspace path to `/home/node/.openclaw/workspace` while keeping host brain repo separate.
- Rationale: Better compatibility with expected OpenClaw runtime layout.
- Tradeoffs: Rowan web still mounts workspace at `/workspace` (intentional service-local path).
- Follow-ups: none immediate.

### 2026-02-22
- Context: Concern raised that Slack-first dev cycle causes context ballooning and weak iterative control.
- Decision: Add evidence-backed research note from OpenClaw docs, Anthropic context-management guidance, and Microsoft Research multi-turn findings.
- Rationale: Validate observed behavior with primary/strong sources before deciding workflow policy.
- Tradeoffs: Confirms need for workflow split (Slack for ops, host/agent surfaces for deep dev loops).
- Follow-ups: bake context hygiene practices into daily operator checklist.

### 2026-02-22
- Context: Need an explicit system-level model that captures both metaphorical orientation and plain operational boundaries.
- Decision: Add `docs/cognitive-architecture.md` as the canonical "how Rowan is embodied" document across repos, containers, and interaction surfaces.
- Rationale: Reduce ambiguity about where memory, runtime, interfaces, and operations live; support cleaner future handoffs and refactors.
- Tradeoffs: Adds one more top-level architecture artifact to maintain as the stack evolves.
- Follow-ups: keep this doc synchronized with compose/runtime changes and role-splitting decisions.

### 2026-02-22
- Context: Migration reached working steady state: containerized Rowan is active with Slack and Cloudflare paths operating.
- Decision: Declare migration complete and freeze current implementation/docs as baseline state.
- Rationale: Establish a stable checkpoint before further feature expansion and role-splitting.
- Tradeoffs: Some hardening enhancements remain backlog items rather than migration blockers.
- Follow-ups: continue iterative hardening from this baseline (digest pinning, cloudflared credential-file mode, backup rehearsal evidence).

### 2026-02-22
- Context: Browser capability needs quick recovery path without full browser-worker container complexity.
- Decision: Adopt host Chrome dedicated-profile path as immediate operating model; add launcher script and runbook.
- Rationale: Enables fast interactive login/MFA bootstrap while keeping Rowan browser state isolated from personal profile.
- Tradeoffs: Slightly weaker isolation than dedicated browser-worker container role.
- Follow-ups: Revisit dedicated browser-worker role later if stronger isolation/concurrency becomes necessary.

### 2026-02-22
- Context: Slack-side Rowan reported inability to manage cron because `openclaw` command was missing in-container.
- Decision: Add container startup wrapper (`openclaw -> node /app/openclaw.mjs`) and perform selective feature-parity merge from legacy config.
- Rationale: Preserve Slack-first cron ergonomics and recover useful non-secret runtime behaviors without reintroducing plaintext credential sprawl.
- Tradeoffs: Parity intentionally excludes legacy embedded secrets (`botToken`, `appToken`, API keys, gateway token) and old host-local workspace path.
- Follow-ups: validate each recovered capability in practice (cron creation from Slack, browser tasks, memory search behavior) and only re-add secret-backed features through env/secret workflow.
