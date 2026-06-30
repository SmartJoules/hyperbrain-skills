---
name: prompt-engineering
description: Systematic prompt engineering for production LLM features. Use when writing or improving a system/user prompt, designing an LLM's output contract, debugging flaky or wrong model output, or tuning cost/latency. Covers prompt structure, role/instruction placement, few-shot examples, structured output (JSON/XML), chain-of-thought, prompt caching, model-tier-aware prompting, and prompt-injection defense. Grounded in the DeJoule stack (AWS Bedrock Converse, Claude/Qwen tiers, prompt caching like Lumen). Use whenever the open question is "how should I prompt the model".
---

# Prompt Engineering

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Write prompts that produce correct, structured, cost-efficient model output
**Version:** 1.0.0

---

## 🎯 When to Use

Writing/fixing a system or user prompt, designing an output contract, debugging wrong/flaky output, or tuning cost/latency. Pairs with [[rag-retrieval]] (presenting retrieved context), [[llm-eval-guardrails]] (proving the prompt works + injection defense), and [[agent-tool-design]] (tool-use prompts). Treat a prompt like code: version it, test it, change it minimally ([[engineering-standards]]).

---

## 1. Prompt anatomy (order matters)

1. **Role / identity** — who the model is and its bar ("senior HVAC analyst; never guess").
2. **Task** — the one job, unambiguous.
3. **Context / retrieved data** — clearly delimited (e.g. fenced or XML-tagged), with source IDs.
4. **Constraints & rules** — what it must/мust-not do; how to handle missing data.
5. **Output format** — exact schema/shape (below).
6. **Examples** — few-shot, if needed (below).

Put **stable, reusable** content first (cacheable); put the **variable** user input last.

## 2. Be specific, show don't tell

- Replace vague adjectives with criteria ("concise" → "≤ 3 sentences, no preamble").
- State the **failure behavior**: what to do when data is missing/ambiguous (say "unknown", ask, or use a default) — models hallucinate to fill silence.
- Positive instructions beat negative ("answer only from CONTEXT" > a list of don'ts).

## 3. Structured output

- For machine-consumed output, demand strict **JSON** (or use native tool/function-calling / Bedrock toolConfig — most reliable). Provide the schema; show one example.
- **XML tags** (`<answer>`, `<reasoning>`) are great for Claude to separate sections you can parse.
- Always **validate** the parsed output at the boundary (schema check); have a repair/retry path. Never trust raw model text as data ([[engineering-standards]] input validation).

## 4. Few-shot examples

- Use 2–5 examples when format/edge-cases matter; make them **diverse** and **representative** (including a tricky/negative case).
- Keep them short — examples are paid input tokens every call (cache them, §6).
- Zero-shot is fine for simple, well-specified tasks (KISS).

## 5. Reasoning

- For multi-step/analytical tasks, allow **chain-of-thought** (or extended thinking) — but keep it out of the user-facing output (put it in a `<reasoning>` tag you discard, or use a reasoning model).
- Don't force CoT on trivial lookups — it's wasted tokens/latency.

## 6. Cost & latency: prompt caching + tiering

- **Prompt caching** (Bedrock/Anthropic): put the large stable prefix (system prompt + retrieved snapshot + few-shots) before a cache point; reused turns cost ~10% input. Lumen caches system+snapshot across its tool loop — do the same.
- **Model-tier-aware prompting** (see Lumen's ladder, [[agentic-engineering]]): cheap model for classification/lookups, mid for analytics, strong only for hard reasoning/verification. Write the prompt for the tier — small models need more explicit structure and examples; strong models need less.
- Trim ruthlessly: truncate tool/retrieved results to what's needed (Lumen caps tool results at 1500 chars).

## 7. Prompt-injection defense (when input includes untrusted content)

- **Separate instructions from data**: never concatenate user/retrieved text into the instruction region; put it in a clearly delimited DATA block and tell the model that block is data, not commands.
- Don't let retrieved/user content change the model's role or tools. Re-assert the system rules after the data block for sensitive tasks.
- **Validate + constrain output** (allow-list actions, schema) so an injected "now do X" can't produce a harmful action. Treat the model's output as untrusted until validated. See [[llm-eval-guardrails]].
- Never put secrets in the prompt; never echo them back.

## 8. Iterate like an engineer

- Change **one thing at a time**; keep a tiny eval set ([[llm-eval-guardrails]]) and re-run after each edit.
- Version prompts (in code/config, not scattered strings); review prompt changes like code.

---

## ✅ Checklist
- [ ] Clear role → task → delimited context → rules → output format → examples
- [ ] Failure/missing-data behavior stated explicitly (no silent hallucination)
- [ ] Machine output uses tool-calling or strict JSON, validated at the boundary
- [ ] Few-shot only where it earns its tokens; examples cached
- [ ] Stable prefix placed for prompt caching; tier-appropriate prompt
- [ ] Untrusted input isolated in a data block; output constrained (injection-safe)
- [ ] Prompt versioned + checked against an eval set after each change
