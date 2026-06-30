---
name: brick
description: Use when answering any Brick Schema or ontology-modeling question: whether a class/predicate is valid, what points belong on equipment, how to model a relationship, or how to validate RDF. Resolve from the ontology-service repo's vendored brick-kb, never from memory.
---

# Brick

Answer Brick questions from the vendored truth in `SmartJoules/ontology-service/brick-kb`.

Do not rely on training memory for Brick class names, aliases, point classes, examples, or validation rules. `Brick.ttl` is large: query it with `tools/brick.ts`; do not read it raw.

---

## Retrieval Commands

Run from the `ontology-service` repo:

```bash
node tools/brick.ts define Chiller
node tools/brick.ts subclasses Equipment
node tools/brick.ts superclasses Air_Handler_Unit
node tools/brick.ts search "pressure sensor"
node tools/brick.ts example Chiller
node tools/brick.ts points Air_Handler_Unit
node tools/brick.ts query --sparql 'SELECT * WHERE { ?s ?p ?o } LIMIT 10'
node tools/brick.ts validate model.ttl
```

Use `brick-kb/INDEX.md` to route a question to the right command or vendored doc.

---

## Procedure

1. Classify the question: definition, hierarchy, search, examples, points, modeling pattern, or validation.
2. Run the matching `tools/brick.ts` command or read the relevant vendored docs under `brick-kb/vendor/docs/modeling/`.
3. Answer from the retrieved result and cite the command/file used.
4. For RDF review, validate locally and report exact failures/fixes.

---

## Notes

- Brick uses `owl:equivalentClass` aliases. If a query returns nothing, run `define` to find the canonical class and aliases.
- For SmartJoules-specific semantics, combine Brick with `sj:` terms from `tools/sj-schema.rq`.
- Neptune does not infer; ontology-service materializes parent types and important inverse edges.
