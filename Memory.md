# Memory

## 2026-03-26 — Project Genesis
- App name: `recon-matching`, port 4017
- Design docs live in `snap-to-text/Docs/` (development_plan.md, master_3.md) — authoritative reference for the full 8-phase plan
- No real data exists — all datasets are synthetic, generated from master doc examples
- 8-phase build plan: Phases 0-6 complete, Phase 7 (RuleCreator) remaining
- Google ADK (`google-adk==1.26.0`) is the target agent framework for Phase 4+ per the plan, but NOT installed — current implementation uses plain Python classes for Orchestrator/Executor instead of ADK LlmAgent/AgentTool
- The `SurfaceLlm` wrapper and `gpt-5-2025-08-07` model reference from the plan are for the original production context — not applicable to our implementation
- DuckDB is the execution engine — no freestyle SQL at runtime (templated operators only)
- Safety boundary: agents may only write to `workspace/outputs/` and `workspace/knowledgebase/.../agent_rule_proposals/`

## 2026-03-26 — Key Architecture Decisions
- **KB_DIR**: `workspace/knowledgebase/rulesets/{workspace}/{ruleset}/`
- **RUN_DIR**: `workspace/outputs/{date}/{workspace}/{ruleset}/{run_id}/`
- Synthetic data uses UNIQUE cusip ranges per scenario to prevent operator cross-contamination (cusips 0-19 exclusions, 20-79 one-to-one, 200-209 many-to-many, 300-305 one-sided, 400+ breaks)
- `_qualify_filter()` in duckdb_skill.py auto-prefixes unqualified columns with table aliases — was needed to fix ambiguous column errors in side filters used in JOINs
- InteractionLog is created per-run in service.py, passed through Orchestrator → Executor → duckdb_skill

## 2026-03-26 — Known Issues
- Phase 7 (RuleCreator + proposal testing) blocked on TODO-6: decide if RuleCreator runs automatically post-waterfall or on-demand
- `_qualify_filter()` is a simple regex — may break on complex nested expressions or CTEs in filters
- EXACT_MATCH_FUND matches fewer records than EXACT_MATCH_BLKCUSIP because FUND records share cusips with generic records and step order matters (step 4 runs before step 5)
- Start script hardcodes `/home/che/anaconda3/bin/python` — not portable
