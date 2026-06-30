# tokensmax — roadmap

Planned capabilities, not yet built. Today's tool is strong for **code-grounded build + review** and —
with `--live` — **data work via MCP**. These items close the remaining gaps.

## `--render` — close the visual blind spot

Headless workers can't see a UI render, so they can't judge whether a component *looks* right or tells
its story well — the biggest gap in real frontend sessions. The fix is a **render loop**:

1. worker builds the component,
2. runs it headless (Playwright/Puppeteer) against real data (pairs with `--live`),
3. **screenshots** it,
4. **reads the screenshot** (vision) and critiques its own output — spacing, hierarchy, legibility, does the story land,
5. refines, repeats until clean.

Turns *build-blind* into **build → see → refine**. Gated like `--live` (it runs a browser + your app).

**Honest scope:** a render loop catches *mechanical* visual defects (cramped, overlapping, unreadable
axis). It does **not** replace taste — "does this beautifully tell the right story to *this* audience"
stays a pairing decision. The fleet builds + self-checks the pixels; you own the narrative.

Needs: a headless browser, a way to run the component (dev server / Storybook), and a screenshot→vision step.

## Codex live-access — end-to-end verify

`--live` is wired and gated for both engines, and the **Claude** MCP path is tested. **Codex** live
tools come from its own `codex mcp add` setup; verify Codex actually calls an MCP tool inside
`codex exec` against a real server before relying on it in anger.
