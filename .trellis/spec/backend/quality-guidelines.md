# Contract Quality Guidelines

> How this repo keeps the client honest against the backend. Backend code
> review standards live in `../knowledge-base-server/.trellis/spec/backend/`.

---

## Contract Drift Prevention

1. DTOs in `lib/shared/models/` are generated-checked against fixture JSON that
   must match the backend OpenAPI schema (`http://localhost:8000/docs`). When a
   round-trip test fails after a backend change, fix the DTO — do not edit the
   fixture to "make it pass" without confirming against `/docs` or
   `src/app/schemas/`.
2. One repository method per endpoint — no duplicate ad-hoc calls to the same
   route from features.
3. Query-param ranges (documents 1–100, search 1–50, chat 1–20) are enforced in
   one constants location, not re-typed per call site.

---

## Verification Before Reporting Done

```bash
flutter analyze && flutter test
```

Plus, when a feature touches a live endpoint, a manual smoke against a running
backend (see directory-structure.md for run commands):

- create → list shows `pending` → detail shows parsed title/tags → edit →
  delete → 404 on revisit
- search with/without `tag`
- chat: happy path streams an answer; stop-backend case shows a graceful error

---

## Cross-Repo Etiquette

- Client never "works around" a backend bug silently: file it and, if trivial,
  fix server-side in the backend repo under its own Trellis workflow.
- CORS, new endpoints, or enum value additions are backend changes — coordinate
  there first, then update this spec's contract notes.
