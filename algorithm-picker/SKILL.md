---
name: algorithm-picker
description: Choose the right algorithm or data structure for a problem before implementing it. Use when a task involves sorting, searching, dedup, graph/tree traversal, dynamic programming, scheduling/optimization, rate limiting, caching/eviction, time-series downsampling, anomaly detection, or forecasting — and you need to pick an approach by input size, constraints, and Big-O trade-offs. Covers general CS algorithms AND the JouleTRACK/DeJoule IoT domain (InfluxDB time-series, Kafka streams, energy/comfort data). Use whenever "what algorithm/data structure should I use" is the open question.
---

# Algorithm Picker

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Pick the right algorithm / data structure for a problem before coding it
**Version:** 1.0.0

---

## 🎯 When to Use This Skill

Use BEFORE implementing whenever the open question is *"which algorithm or data structure fits?"* — sorting/search, dedup, graph/tree work, DP, scheduling/optimization, rate limiting, caching, or the IoT-domain problems below. Pairs with [[engineering-standards]] (the picked algorithm still obeys SOLID/perf rules) and [[agentic-engineering]] (use it inside the plan step).

For trivial cases (a handful of items, a one-off loop) skip the analysis — `array.sort()` / a plain loop is correct (KISS/YAGNI).

---

## 🧭 Selection Method (do this first)

Answer these, then pick:

1. **Input size (n)** — tens? thousands? millions? streaming/unbounded?
2. **Constraints** — latency budget, memory budget, real-time vs batch, exact vs approximate-OK.
3. **Access pattern** — one-shot, repeated queries, inserts/deletes over time, sorted output needed?
4. **Data shape** — already sorted/partially sorted? unique keys? skewed/duplicates? time-ordered?
5. **Correctness bar** — must be exact, or is a bounded-error estimate acceptable (huge cost savings for analytics)?

Then state the choice as: **picked X because (n, constraint) → O(time)/O(space); rejected Y because …**. Always name the runner-up and why you didn't pick it.

---

## PART A — General Algorithms & Data Structures

### Data structure picker
| Need | Use | Why |
|------|-----|-----|
| Membership / dedup / counts by key | **Hash set / map** | O(1) avg lookup |
| Membership at huge scale, approx OK | **Bloom filter / HyperLogLog** | sublinear memory; bounded false-positive / cardinality estimate |
| Ordered keys + range queries | **Balanced BST / sorted array / B-tree** | O(log n) search + in-order range |
| Top-K / priority / scheduling | **Heap (priority queue)** | O(log n) push/pop, O(1) peek |
| FIFO / sliding window | **Queue / deque (ring buffer)** | O(1) ends; bounded memory |
| Prefix / autocomplete / dictionary | **Trie** | prefix search in O(key length) |
| Disjoint grouping / connectivity | **Union-Find (DSU)** | near-O(1) union/find |
| Fast ordered + hash (LRU) | **Hash map + doubly linked list** | O(1) get/put with eviction |

### Algorithm picker by problem
- **Sorting:** library sort (Timsort/introsort) by default; **counting/radix** only for small integer ranges; **heap/merge** when stability or external/streaming sort matters. Don't hand-roll.
- **Search:** hash lookup if unordered; **binary search** if sorted; **two pointers / sliding window** for contiguous subarray/substring; **BFS/DFS** for graphs.
- **Graph:** BFS (unweighted shortest path), **Dijkstra** (non-negative weights), **Bellman-Ford** (negative edges), **A\*** (heuristic), **topological sort** (DAG ordering/deps), **Union-Find** (components/MST-Kruskal).
- **Optimization / combinatorial:** **dynamic programming** (overlapping subproblems + optimal substructure: knapsack, edit distance, intervals); **greedy** (exchange-argument holds: interval scheduling, Huffman); **backtracking/branch-and-bound** (constraint search) — and accept heuristics when exact is NP-hard.
- **Strings:** KMP/Aho-Corasick (multi-pattern), rolling hash (Rabin-Karp), suffix structures for heavy substring work.
- **Rate limiting:** **token bucket** (bursty) vs **sliding-window log/counter** (smooth); pick by burst tolerance.
- **Concurrency-safe counters/sets at scale:** CRDTs / sharded counters.

### Complexity sanity check
n ≤ ~10⁶ per request → aim ≤ O(n log n). Anything O(n²)+ on large n, a query-in-a-loop (N+1), or an unbounded cache is a **red flag** — revisit (ties to [[engineering-standards]] perf rules).

---

## PART B — JouleTRACK / DeJoule IoT Domain

Ground choices in the real stack: **InfluxDB/Timestream** time-series, **Kafka** streams, **Redis** cache, PostgreSQL/DynamoDB, energy + comfort sensor data.

### Time-series downsampling / aggregation
- **Default:** push aggregation **into the query** (Influx `aggregateWindow` / Timestream binning) — never pull raw points and reduce in app (N+1 over points).
- **Method:** `mean`/`last` for trends; **LTTB (Largest-Triangle-Three-Buckets)** when the chart must keep visual shape with few points; `min/max` per bucket to preserve spikes (the scheduler status spikes care about this).
- **Preserve nulls** — do NOT `fill(0)` on sensor gaps (domain rule). Cache downsampled results in Redis **with TTL/eviction** (the comfort-index widget already does this).

### Anomaly / fault detection on sensor streams
- Start simple: **threshold + hysteresis** (avoid alert flapping) and **rolling mean/median + MAD/z-score** over a sliding window.
- Seasonal data (HVAC daily/weekly cycles): **EWMA** or **STL/seasonal decomposition** residuals; **Holt-Winters** if seasonality is strong.
- Only escalate to ML (isolation forest / autoencoder) when simple statistics demonstrably miss faults — and keep it explainable.

### Scheduling / setpoint optimization (scheduler feature)
- Conflict-free time bands / overlaps → **interval scheduling (greedy)** or a **sweep line** over start/stop events.
- Recurring cron windows → parse to intervals (the repo's cron→hour-window parser), then merge with **interval merge**.
- Multi-constraint setpoint optimization → start with greedy/rule-based; reach for LP/MILP or search only if rules can't express the objective.

### Forecasting (load / consumption / comfort)
- Baseline: **moving average / EWMA / Holt-Winters** (cheap, explainable).
- Regression on drivers (weather, occupancy) before deep models. Prefer interpretable + cheap unless accuracy gap justifies the cost (cost-aware, like [[agentic-engineering]]).

### Stream processing (Kafka)
- **Windowing:** tumbling (fixed buckets), hopping (overlap), session (gaps) — pick by the metric's semantics.
- **Dedup / exactly-once-ish:** idempotency keys + a bounded **seen-set with TTL** (not unbounded). Commit offsets **after** processing (see [[kafka-patterns]] / [[engineering-standards]]).
- **Joins/enrichment:** keep lookup state in a bounded local cache (LRU+TTL), not a per-message DB call.

### Caching & eviction (Redis)
- Pick eviction by access pattern: **LRU** (recency), **LFU** (popularity), **TTL** (freshness/time-bound), size cap. **Never unbounded.** Invalidate on the corresponding write. (See [[engineering-standards]] connection/cache rules.)

---

## ✅ Output When Picking

State briefly:
- **Problem framing**: n, constraints, access pattern, exact-vs-approx.
- **Chosen approach** + its time/space complexity.
- **Runner-up rejected** and why.
- **Domain caveats** (preserve nulls, push aggregation to query, bounded cache, offset-after-process) where relevant.

Then implement following [[engineering-standards]]. Don't over-engineer — the simplest approach that meets the constraints wins.
