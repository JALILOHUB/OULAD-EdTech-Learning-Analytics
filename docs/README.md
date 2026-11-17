# Project Documentation Index

This index distinguishes current operating references from historical evidence. The repository is the authoritative source for current technical state, analytical evidence, decisions, and roadmap. Conversation memory is reserved for durable owner instructions and working preferences, not a parallel copy of changing project facts.

## Current / authoritative references

| File | Authority |
|---|---|
| `analysis_progress_ledger.md` | Current roadmap status, executed work-order/query evidence, decisions, open questions, repository state, and next work order |
| `analysis_log.md` | Detailed chronological analytical evidence, results, limitations, and decisions |
| `architecture.md` | Current repository and data-layer architecture |
| `data_access_strategy.md` | Source access and ingestion approach |
| `data_dictionary.md` | Dataset fields and definitions |
| `analytical_work_order_plan.md` | Analytical work-order structure |
| `analytical_readiness_work_order.md` | Readiness and controlled execution conventions |
| `AN8_implementation_specification.md` | Current AN8 metric, extraction, and curated-table design |
| `AN8_phase1_execution_handover.md` | Current AN8 execution sequence and safety boundary |
| `../reports/AN8_initial_results_and_scope_extension.md` | Initial AN8 execution evidence, rationale for scope extension, cleaning strategy, and next analytical gates |

When references disagree, use the most recent evidence-backed entry in the progress ledger and analysis log, then reconcile the affected document. A plan or handover never proves execution.

## Historical evidence

The following phase documents and notebooks retain prior work and should not be rewritten merely because the roadmap has advanced:

- `AN5_engagement_sensitivity_plan.md`
- `AN6_recorded_vle_activity_patterns_plan.md`
- `AN7_outcome_associations_plan.md`
- `notebooks/05_wo2_analytical_investigation.ipynb`
- `notebooks/07_an5_engagement_sensitivity.ipynb`
- `notebooks/08_an6_recorded_vle_activity_patterns.ipynb`
- `notebooks/09_an7_outcome_associations.ipynb`
- `reports/AN7_final_report.md`

These are evidence of completed scopes, not instructions to rerun them. Retained notebook outputs are historical execution evidence unless a later entry explicitly records a new run.

## Superseded / working references

- `repository_snapshot_2026-10-30.md` is a dated historical snapshot, not a live repository inventory.
- `releases/` contains release-specific historical notes.
- `AN8_independent_review_and_execution_plan.md` is a preparation review; the current implementation specification and phase handover carry the operational AN8 design.
- Temporary branches, handovers, and working plans must not override the ledger or canonical SQL files.

## Duplicate and archive policy

Do not delete or move historical documents solely because their plans are superseded. Preserve evidence and label its status. Remove a duplicate only after confirming that it contains no unique result, decision, provenance, or interpretation. Prefer updating an existing authoritative document over creating a second report for the same phase.

No bulk archive migration or deletion is authorized by this index. Any future move, merge, or deletion must be reviewed against the actual repository tree and proposed as a separate controlled change.
