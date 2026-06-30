---
name: engineering-standards
description: Mandatory engineering standards for writing ANY code. Use whenever creating, modifying, or reviewing code, designing a system, or adding a Kafka/Redis/DB integration. Enforces OOP + SOLID, the strategy/decorator/observer/factory/builder design patterns, DRY/KISS, minimal-diff changes, robust connection standards (Kafka heartbeat/offset/lag, Redis singleton/retry/safe handling), and resilience: no memory leaks, no unhandled promises, explicit error/loading/empty/partial states, query optimization, fewer DB calls, and caching with an eviction strategy.
---

# Engineering Standards (Mandatory)

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Non-negotiable coding and system-design standards applied to ALL code
**Version:** 1.0.0

---

## 🎯 When to Use This Skill

Apply **automatically and always** when:
- Writing or modifying any code (frontend, backend, IoT, scripts)
- Designing or reviewing a system or feature
- Adding or touching a Kafka, Redis, MQTT, or database integration
- Reviewing a PR or diff

This skill is a hard requirement, not a suggestion.

---

## 1. Design Principles (apply to every change)

### OOP + SOLID — mandatory
- **S** — Single Responsibility: one class/function, one reason to change. Functions < 50 lines.
- **O** — Open/Closed: extend via new types/strategies, don't edit working code to add behavior.
- **L** — Liskov Substitution: subtypes must be drop-in for their base; no surprising overrides.
- **I** — Interface Segregation: small, focused interfaces over fat ones.
- **D** — Dependency Inversion: depend on abstractions (interfaces), inject dependencies, never `new` a concrete service deep inside business logic.

### DRY / KISS / minimal change
- **DRY**: search for existing logic before writing new logic. Extract shared code; never copy-paste.
- **KISS**: simplest solution that works. No speculative abstraction (YAGNI).
- **Minimum change**: smallest correct diff. Don't refactor unrelated code, rename, or reformat in the same change. Touch only what the task requires.

### Use design patterns deliberately — pick the right one
| Pattern | Use when |
|---------|----------|
| **Strategy** | Multiple interchangeable algorithms/behaviors chosen at runtime (e.g. pricing, retry policy, export format). Replaces `if/else` / `switch` on a type. |
| **Factory** | Object creation logic varies or should be centralized; caller shouldn't know concrete classes. |
| **Builder** | Constructing an object with many optional params / step-by-step config (avoids telescoping constructors). |
| **Observer** | One change must notify many subscribers (events, pub/sub, reactive state, RxJS streams). |
| **Decorator** | Add behavior (logging, caching, retry, auth) without modifying the wrapped object. |
| **Adapter** | Bridge an incompatible external API to your internal interface. |
| **Repository** | Encapsulate data access behind an interface (`findById`, `create`, …) so storage is swappable and testable. |

> Don't force a pattern where a plain function suffices (KISS). Use one only when it removes branching, duplication, or coupling.

---

## 2. Resilience Checklist (every function / component)

- [ ] **Memory leaks** — clean up everything: unsubscribe (`takeUntil`/`async` pipe in Angular, cleanup in React `useEffect`), clear timers/intervals, remove event listeners, close streams/connections, abort in-flight requests.
- [ ] **Unhandled promises** — never leave a promise floating. `await` it, `.catch()` it, or explicitly `void` it with a handler. No async function without try/catch or `.catch`.
- [ ] **Error handling** — handle errors at every boundary. `catchError` on every observable. User-friendly message in UI; detailed context logged server-side. Never silently swallow.
- [ ] **Loading state** — every async UI shows an explicit loading indicator.
- [ ] **Error state** — every async UI has a visible error state + retry path.
- [ ] **Empty state** — render a defined empty/zero-data state, never a blank screen.
- [ ] **Partial data** — render what's available, degrade gracefully when some data is missing or a sub-request fails; don't crash the whole view.
- [ ] **Input validation** — validate at system boundaries (API inputs, query params, external responses). Fail fast with clear messages. Never trust external data.
- [ ] **No `any`** — type everything explicitly.

---

## 3. Database & Performance

- [ ] **Query optimization** — index the columns you filter/join on; avoid full scans; `SELECT` only needed columns; add `LIMIT`/pagination to list queries.
- [ ] **Fewer DB calls** — eliminate N+1 (batch, `JOIN`, or `IN`). Fetch in one round-trip where possible. No queries inside loops.
- [ ] **Caching with eviction** — cache expensive/repeated reads. ALWAYS define an eviction strategy: TTL, LRU/LFU max-size, or explicit invalidation on write. Never an unbounded cache (it becomes a memory leak). State the strategy in the code/PR.
- [ ] **Cache invalidation** — invalidate or update the cache on the corresponding write so reads don't serve stale data.
- [ ] **Bounded everything** — bound queues, batches, retries, and result sets. No unbounded growth.

---

## 4. Kafka Connection Standards

Every Kafka producer/consumer MUST follow these:

- [ ] **Heartbeat** — configure `heartbeat.interval.ms` (~1/3 of `session.timeout.ms`) so the broker knows the consumer is alive; set `session.timeout.ms` and `max.poll.interval.ms` deliberately for the workload.
- [ ] **Offset management** — explicit, intentional offset commits. Prefer **manual commit after successful processing** (`enable.auto.commit=false`) for at-least-once; never commit before the message is processed. Choose and document `auto.offset.reset` (`earliest`/`latest`).
- [ ] **Consumer lag** — monitor and expose consumer-group lag; alert when it grows. Size partitions/consumers so lag stays bounded.
- [ ] **Idempotency / delivery** — idempotent producer (`enable.idempotence=true`) and idempotent consumer processing to tolerate redelivery.
- [ ] **Rebalance safety** — handle partition revoke/assign (commit on revoke); make processing resumable.
- [ ] **Reliability** — `acks=all`, sensible `retries` + backoff, and a dead-letter topic for poison messages.
- [ ] **Graceful shutdown** — close consumers/producers on shutdown so offsets are committed and the group rebalances cleanly. (Ties to the memory-leak rule.)
- [ ] **Error handling** — retry transient errors with backoff; route permanent failures to DLQ; never crash the whole consumer on one bad message.

## 5. Redis Connection Standards

- [ ] **Singleton client** — one shared, reused client/pool per process. NEVER create a new connection per request/operation. Inject it (Dependency Inversion).
- [ ] **Safe handling** — connection pooling, sensible `connectTimeout`/`commandTimeout`, and TLS/auth where required.
- [ ] **Retry** — automatic reconnect with exponential backoff + jitter and a retry strategy for commands on transient failures; cap retries so it can't spin forever.
- [ ] **Graceful degradation** — if Redis is down, the app degrades (fall back to source/DB) instead of crashing; cache is an optimization, not a hard dependency.
- [ ] **Eviction / TTL** — set TTLs on cached keys and rely on an eviction policy (e.g. `allkeys-lru`); never let memory grow unbounded.
- [ ] **Cleanup** — close the client on shutdown; remove key listeners/subscriptions you add.
- [ ] **Error handling** — handle `error`/`reconnecting`/`end` events; log and surface; don't let an unhandled Redis error take down the process.

> The same connection discipline (singleton/pool, retry+backoff, graceful shutdown, error events) applies to MQTT, DB pools, and any long-lived connection.

---

## 6. Before You Say "Done" — Quality Gate

- [ ] SOLID respected; the right pattern used (or deliberately none) — no branchy `if/else` that a Strategy/Factory would remove
- [ ] DRY/KISS; minimal diff (nothing unrelated touched)
- [ ] No memory leaks (subscriptions/timers/listeners/connections cleaned up)
- [ ] No unhandled promises; errors handled at every boundary
- [ ] Loading + error + empty + partial-data states all handled (UI)
- [ ] Queries optimized; N+1 removed; fewer DB calls
- [ ] Cache has a defined eviction strategy and is invalidated on write
- [ ] Kafka: heartbeat, offset commit policy, lag monitored, DLQ, graceful shutdown
- [ ] Redis: singleton/pool, retry+backoff, TTL/eviction, graceful degradation, cleanup
- [ ] Inputs validated; no `any`; types explicit

> Rule of thumb: if a reviewer can point at one of these boxes and it's unchecked, the code is not done.
