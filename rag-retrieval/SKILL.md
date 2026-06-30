---
name: rag-retrieval
description: Production Retrieval-Augmented Generation patterns. Use when building or improving any feature that retrieves context to ground an LLM answer — document Q&A, semantic search, codebase/knowledge-base assistants, or graph-RAG over a topology. Covers chunking, embeddings, vector + hybrid (keyword+vector) search, reranking, graph-RAG, grounding/citations, freshness/invalidation, and retrieval evaluation. Grounded in the DeJoule stack (AWS Bedrock Titan embeddings, Neptune graph, like Lumen). Use whenever the question is "how do I retrieve the right context to ground the model".
---

# RAG & Retrieval

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Build retrieval that grounds LLM answers in correct, fresh, cited context
**Version:** 1.0.0

---

## 🎯 When to Use

Building/improving anything that fetches context to ground an LLM: doc Q&A, semantic search, KB assistants, graph-RAG. Pairs with [[prompt-engineering]] (how the retrieved context is presented), [[llm-eval-guardrails]] (measuring retrieval quality), [[agent-tool-design]] (retrieval-as-a-tool), and [[lumen-knowledge-base]] (a live graph-RAG example). Enforce [[engineering-standards]] (cache eviction, connection rules).

> **Retrieve the least that fully grounds the answer.** More context ≠ better — it adds cost, latency, and distraction. Precision first.

---

## 1. Decide if you even need RAG

- Knowledge is **small + static** → put it in the system prompt (no retrieval).
- Knowledge is **structured/relational** → query it directly (SQL/graph), not vector search.
- Knowledge is **large, unstructured, changing, or user-specific** → RAG.
- Often **hybrid**: structured query for facts + vector search for prose. (Lumen does graph for topology + Influx for telemetry + embeddings only to disambiguate point names.)

## 2. Chunking

- Chunk on **semantic boundaries** (headings, functions, paragraphs), not fixed char counts that split mid-thought.
- Typical 200–500 tokens with ~10–20% **overlap**; smaller for precise lookup, larger for narrative.
- Keep **metadata** per chunk (source, title, section, timestamp, IDs) — needed for filtering, citations, and invalidation.
- Code: chunk by symbol (function/class) — see [[graphify-integration]] / [[local-kb]] for precomputed code context (cheaper than embedding raw files).

## 3. Embeddings

- DeJoule default: **AWS Bedrock Titan Embed v2** (1024-dim, unit-normalized) — what Lumen's `embedder.service` uses.
- Embed query and chunks with the **same** model; normalize; use cosine similarity.
- **Cache embeddings** (content-hash key) — never re-embed unchanged text. Persist (Redis/Postgres), not just per-process. (Lumen currently caches in-process only — a known gap.) Cache MUST have eviction per [[engineering-standards]].

## 4. Search strategy (pick per data shape)

| Strategy | Use when |
|----------|----------|
| **Vector (ANN)** | Semantic similarity over prose; paraphrase-tolerant |
| **Keyword/BM25** | Exact terms, IDs, codes, rare tokens vectors miss |
| **Hybrid (vector + keyword)** | Default for most real corpora — fuse scores (RRF) |
| **Metadata pre-filter** | Always scope by site/tenant/date BEFORE similarity (correctness + speed) |
| **Graph traversal** | Relational/topology questions — traverse edges, don't embed ("which pumps feed chiller X") |

## 5. Reranking

- First-stage retrieval favors recall (get ~20–50 candidates); a **reranker** (cross-encoder or a cheap LLM judge) reorders for precision; keep top 3–8.
- Worth it when first-stage is noisy or the window is tight. Skip for small/clean corpora (KISS).

## 6. Grounding & citations (non-negotiable for trust)

- Pass retrieved chunks with their **source IDs**; instruct the model to answer **only** from them and cite.
- **Verify** concrete claims against the retrieved context before returning (Lumen's verify-gate pattern — see [[llm-eval-guardrails]]).
- If retrieval returns nothing relevant, the model must say "I don't have that" — never fabricate. Pass an explicit "no results" signal.

## 7. Freshness & invalidation

- Stale retrieval = wrong answers. Re-embed/re-index on the source's write; track `updatedAt`.
- Cache retrieval results with **short TTL + invalidation on write** (per [[engineering-standards]]); never unbounded.
- For live data (telemetry), don't cache the values — cache the structure/embeddings, fetch values fresh.

## 8. Evaluate retrieval (don't guess)

- Build a small **golden set** (query → expected source chunks). Measure recall@k, precision@k, MRR.
- Track end-to-end: did the cited source actually support the answer? (faithfulness). See [[llm-eval-guardrails]].
- Log retrievals (query, returned IDs, scores) so you can debug "why did it miss".

---

## ✅ Checklist
- [ ] Confirmed RAG is the right tool (vs prompt / direct query / graph)
- [ ] Semantic chunking + metadata + same embedding model for query & chunks
- [ ] Metadata pre-filter (tenant/site/date) before similarity
- [ ] Hybrid search where keywords/IDs matter; rerank if first-stage is noisy
- [ ] Answers grounded in retrieved chunks + citations; "no results" path handled
- [ ] Embeddings + retrieval cached with eviction + invalidated on write
- [ ] Golden-set eval (recall@k / faithfulness) before shipping
