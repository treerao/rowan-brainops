# Research Note: Context Bloat and Slack-First Dev Friction

Date: 2026-02-22

## Question
Is it a known/confirmed issue that long-running dev workflows (especially via Slack chat) cause context bloat and degraded reliability?

## Short answer
Yes. This is confirmed by OpenClaw docs, Anthropic platform guidance, and Microsoft Research findings.

## Evidence from strong sources

## 1) OpenClaw explicitly documents context growth mechanics
OpenClaw defines context as all model inputs and states it is bounded by model context windows. It includes system prompt, history, tool calls/results, attachments, and tool schemas.

- Context docs: https://docs.openclaw.ai/concepts/context
- Key points:
  - context includes tool calls/results and attachments
  - tool schemas count toward context even when not visible as text
  - `/context detail` is provided to inspect heavy contributors

OpenClaw also documents that long-running chats accumulate messages + tool results and therefore need compaction/pruning.

- Compaction: https://docs.openclaw.ai/concepts/compaction
- Session pruning: https://docs.openclaw.ai/concepts/session-pruning

Inference: your observed context ballooning in long dev loops is expected in this architecture.

## 2) Anthropic confirms agent context exhaustion in long-running tasks
Anthropic’s context-management announcement states production agents often exhaust effective context windows as tool results accumulate, and introduces context editing/memory specifically to address this.

- https://claude.com/blog/context-management

Inference: this is a general agent-system issue, not unique to your setup.

## 3) Multi-turn reliability degradation is empirically documented
Microsoft Research (with Salesforce Research) reports significant multi-turn degradation and increased unreliability in simulated conversations.

- Paper page: https://www.microsoft.com/en-us/research/publication/llms-get-lost-in-multi-turn-conversation/
- arXiv: https://arxiv.org/abs/2505.06120

Reported finding: average performance drop in multi-turn settings, with errors compounding after early wrong turns.

Inference: your “true dev cycle over long chat gets hard to manage” observation is consistent with published results.

## 4) Slack channel mechanics can add operational friction
Slack reply/thread behavior is explicit in API semantics (`thread_ts`, `reply_broadcast`), and OpenClaw Slack channel docs include reply mode controls (`off|first|all`) plus thread/session routing behavior.

- Slack `chat.postMessage`: https://docs.slack.dev/reference/methods/chat.postMessage/
- OpenClaw Slack: https://docs.openclaw.ai/channels/slack

Inference: Slack can be productive for ops/chat, but deep iterative dev cycles often require stronger context tooling than raw threaded chat.

## Practical implication for Rowan
- Keep Slack for command/control and quick interactions.
- Use host/terminal (or dedicated agent surfaces) for heavy multi-step dev cycles.
- Use explicit context hygiene (`/context detail`, compaction, pruning, session resets) as normal operating practice.
