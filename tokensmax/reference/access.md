# Live access & blind spots

Headless workers can't see two things; screen for them before dispatching.

## Live data — gated `--live`

A worker can't reach the user's DB / API / graph / metrics **unless granted**. If an engine has
`mcp_config` set (Codex: `codex mcp add …`), propose `--live` and **ask the user**: *"the worker will
query your live system with your credentials — grant for this run?"* On yes, dispatch
`--live --grant-live` (a separate, stronger gate than `--yes`; a human typing it in a terminal is
auto-granted). If it's not configured or the user declines, **run the query yourself in this session** —
never let a blind worker speculate about live data (it will confidently invent answers).

## Visual judgment

No worker can see a render, so **judging "does it look right"** (spacing, colour, hierarchy) stays with
the user's eyes. But **building** the UI/component from a spec is normal, dispatchable build work — the
fleet's sweet spot. Never refuse to dispatch a UI build just because its output is visual; dispatch the
build, then the user reviews the render. (Planned: a `--render` loop — screenshot + vision self-check —
see ROADMAP.md.)

## Already known

Don't dispatch to "confirm" something you already know — that's pure waste.
