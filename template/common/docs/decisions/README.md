# Architectural Decision Records (ADRs)

This directory contains the Architectural Decision Records for **{{PROJECT_NAME}}
({{PROJECT_SHORT}})**.

## Purpose

ADRs are a lightweight record of significant design and architectural choices. Each one documents:

* **Context**: what was the problem and the environment at the time?
* **Decision**: what choice was made to address it?
* **Consequences**: what are the positive, negative, and neutral trade-offs?

An ADR is immutable once accepted. If a decision is revisited, write a new ADR that supersedes the
old one and update the status of both — never rewrite history.

## Structure of an ADR

Each ADR is a Markdown file named with a sequential ID and a short slug:

* `0001-some-decision.md`
* `0002-another-decision.md`

Start from [`0000-adr-template.md`](0000-adr-template.md), or run:

```bash
make adr TITLE="Short decision title"
```

## Statuses

| Status | Meaning |
| :----- | :------ |
| Proposed | Under discussion; not yet binding. |
| Accepted | In effect. |
| Superseded by ADR-XXXX | Replaced by a later decision. |
| Deprecated | No longer applies, with no direct replacement. |

## Index of Decisions

1. [0001-record-architecture-decisions.md](0001-record-architecture-decisions.md) — Record architectural decisions as ADRs.
