# Artifact Registry

This project's artifact state. Types, short names and `CrossReference
Candidates` come from the framework catalog
(`framework/registry/artifact-catalog.md`); this file only records where
each document lives in *this* project and the next version to use.

Delete rows for types you don't use. Add a row the first time you create a
document of a type. `Primary File` may contain a glob (e.g.
`docs/uc-*/uc.md`); `framework/scripts/find-crossreferences.sh` reads it.

| Short Name | Artifact Type | Primary File | Next Available Version |
| --- | --- | --- | --- |
| BC | Business Case | docs/business-case.md | 002 |
| SA | Stakeholder Analysis | docs/stakeholder-analysis.md | 002 |
| PP | Project Plan | docs/project-plan.md | 002 |
| MIL | Milestone / Gateway | docs/milestones/*.md | 005 |
| US | User Story | docs/user-stories.md | 002 |
| UC | Use Case | docs/uc-*/uc.md | 002 |
| SSD | System Sequence Diagram | docs/uc-*/ssd.md | 002 |
| OC | Operation Contract | docs/uc-*/oc.md | 002 |
| SD | Sequence Diagram | docs/uc-*/sd.md | 002 |
| DM | Domain Model | docs/domain-model.md | 003 |
| DICT | Domain Dictionary (PO and IT terms) | docs/dictionary.md | 002 |
| UCD | Use Case Diagram | docs/use-case-diagram.md | 002 |
| RC | SQA Review Record | docs/sqa/reviews/rc-*.md | 019 |
| TM | Traceability Matrix | docs/sqa/traceability-matrix.md | 002 |

## Languages

Set the PO language when the project starts; `project-planning` asks for it
if it is missing. A translated artifact is named `<artifact>.<language>.md`
(for example `business-case.da.md`); the English file stays the source.

| Setting | Value |
| --- | --- |
| PO language | en |
| High-level register | IT Executive English |
| Technical register | IT Professional English |

| Artifact types | Register | Also kept as a PO-language file |
| --- | --- | --- |
| BC, KPI, PP, MIL | IT Executive English | Yes |
| SA, BMC, BPMN, UCD, US, UC, SSD, DM, RA, GOV, DICT | IT Professional English | Yes |
| OC, SD, DCD, ERD, ADR, TM, RC, QC, source code | IT Professional English | No |

## Notes

- "Next Available Version" is the zero-padded (3-digit) version to use the
  *next* time a new document of that type is created. Increment it only when
  a brand-new document is created, not when an existing document's
  `## Version History` gets a row.
- `ADR` uses 4 digits (`0001`); `RC` is sequential across all artifact types.
