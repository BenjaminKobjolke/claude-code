# Command Improvement Plan

Generated: 2026-03-27
Based on: Claude Code Insights Report (2026-03-20 to 2026-03-26)
Stats: 211 sessions, 183 analyzed, 2,295 messages, 302 commits, 7 days

---

## Summary

### Key Findings

Your 41 commands cover most workflow categories well — git, planning, analysis, testing, bugs, refactoring, and handoffs are all represented. However, cross-referencing your **top activities** and **friction points** against the command inventory reveals clear gaps:

| Metric | Value |
|--------|-------|
| Top friction: Wrong Approach | 16 events |
| User Rejected Actions | 12 events (239 tool rejections total) |
| Buggy Code shipped | 11 events |
| Misunderstood Request | 5 events |
| Dissatisfied sessions | 19 out of 183 |

**The root cause pattern**: Claude dives into code without checking project conventions, writes feedback files when code is expected, and picks non-DRY approaches. These are behavioral guardrails problems, not capability gaps — and they're solvable with better command design.

### Activity Coverage

| Activity (sessions) | Covering Commands | Gap? |
|---------------------|-------------------|------|
| Git Operations (41) | git:commit, git:get-url, git:setup | Commit separation enforcement weak |
| Bug Fix (29) | bugs:fix, bugs:collect | No TDD-first workflow built in |
| Feature Request (22) | plan:feature, plan:implement | No convention-check gate |
| Feature Implementation (18) | plan:implement | No pre-implementation checklist |
| Feedback Processing (12) | feedback:implement-new-api-changes | Biggest friction source — needs guardrails |
| Documentation (11) | docs:generate | Adequate |
| Frontend UI/Templates (10) | — | No DRY-check command for template changes |

---

## New Commands Needed

### 1. `convention:check` — Pre-implementation convention scanner

**Rationale**: 16 wrong-approach events + 12 user rejections stem from Claude ignoring existing project patterns (wrong translation format, raw HTML instead of widgets, per-file fixes instead of global CSS).

**What it does**:
- Before any implementation, scan the codebase for relevant existing patterns
- Check for reusable components (date_field, hub_link, etc.)
- Verify translation format (:param not %param%)
- Check for DRY opportunities (global CSS vs per-template)
- Output a conventions checklist the implementation must follow

**Impact**: Could prevent ~28 friction events (wrong approach + user rejections)

### 2. `feedback:implement-safe` — Guardrailed feedback processing

**Rationale**: The existing `feedback:implement-new-api-changes` is the #1 friction source. Claude repeatedly writes feedback files instead of code, misses content in reports, and uses wrong conventions.

**What it does**:
- Hard rule: NEVER write feedback files, ONLY implement code changes
- Read ALL feedback files completely before starting (no partial reads)
- Run convention:check before each implementation
- Use existing UI components (verified by grep)
- Run tests + analysis after changes
- Present summary before committing

**Impact**: Could eliminate friction across 10+ feedback-processing sessions per week

### 3. `tdd:bugfix` — Test-driven bug fix workflow

**Rationale**: 11 buggy code events and 29 bug-fix sessions show bugs ship without adequate test coverage. A TDD-first command would catch issues pre-commit.

**What it does**:
1. Write a failing test that reproduces the bug
2. Run tests — confirm failure
3. Implement minimal fix
4. Run tests — confirm green
5. Run static analysis
6. Present diff for review

**Impact**: Could prevent 11 buggy-code events and improve the 29 bug-fix sessions

### 4. `dry:check` — Post-implementation DRY audit

**Rationale**: plan:dry exists but only works on plans. User repeatedly has to redirect Claude from per-file approaches to global/shared solutions after code is already written.

**What it does**:
- After implementation, scan changed files for duplication
- Check if any per-file change could be a single shared rule/component
- Compare against existing reusable components in the project
- Suggest consolidation opportunities

**Impact**: Prevents wasted work (e.g., 9 template edits → 1 CSS rule)

---

## Existing Commands to Enhance

### 1. `feedback:implement-new-api-changes`

**Problem**: Biggest friction source — Claude writes feedback files instead of code, misses file content, uses wrong conventions.

**Enhancement**:
- Add explicit guard: "NEVER write feedback files — ONLY implement code changes unless explicitly asked"
- Add step: "Read ALL feedback files completely — re-read if content seems incomplete"
- Add step: "Before implementing, grep for existing UI components and patterns to reuse"
- Add step: "Verify translation format uses :param (not %param%) before committing"

### 2. `bugs:fix`

**Problem**: No test-first discipline — fixes ship without verifying they actually work.

**Enhancement**:
- Add step before implementation: "Write a failing test that reproduces this bug"
- Add step after fix: "Run full test suite and static analysis"
- Add step: "Check DI container if new services were added"

### 3. `plan:feature`

**Problem**: Claude jumps into code without checking conventions, leading to 16 wrong-approach events.

**Enhancement**:
- Add step: "Before listing files to modify, grep for existing patterns and reusable components"
- Add step: "List which existing UI components/patterns to reuse (must check, not assume)"
- Add step: "Wait for explicit user approval before ANY file modifications"

### 4. `validate:pre-commit`

**Problem**: DI wiring bugs and wrong translation formats slip through to production.

**Enhancement**:
- Add check: Verify DI container includes all services referenced in new/modified controllers
- Add check: Translation keys use :param format (not %param%)
- Add check: No raw HTML inputs where project widgets exist (date_field, etc.)

### 5. `git:commit`

**Problem**: Unrelated changes get bundled; user repeatedly asks for separate commits.

**Enhancement**:
- Add step: "Group changed files by logical concern before staging"
- Add step: "If changes span multiple concerns, propose multiple commits"
- Add step: "Ask user to confirm commit grouping before proceeding"

---

## Redundant Commands

| Command | Issue | Recommendation |
|---------|-------|----------------|
| `flutter:check-local-dependencies` | Not a Flutter project (0 sessions) | N/A for this project — keep in shared repo |
| `flutter:update-packages` | Not a Flutter project (0 sessions) | N/A for this project — keep in shared repo |
| `python:upgrade-to-uv` | Not a Python project (0 sessions) | N/A for this project — keep in shared repo |
| `debug:create-debug` | No usage in insights data | Review if still needed |
| `release:create-release` vs `github:create-release` | Overlap in purpose | Consider consolidating or clarifying when to use which |
| `analyze:setup` vs `testing:setup` | Both setup bat files for post-feature checks | Could be a single `setup:quality-checks` command |

---

## Integration Opportunities

### Chain Commands for End-to-End Workflows

| Trigger Command | Should Auto-Chain To | Why |
|----------------|----------------------|-----|
| `feedback:implement-*` | `convention:check` → implementation → `verify:after-change` → `git:commit` | Full feedback-to-commit pipeline with guardrails |
| `bugs:fix` | `tdd:bugfix` → `verify:after-change` → `git:commit` | TDD bug fix with auto-verification |
| `plan:implement` | `convention:check` → implementation → `dry:check` → `verify:after-change` | Convention-aware implementation with DRY audit |
| `git:commit` | `validate:pre-commit` (enforce, not suggest) | Catch DI wiring and convention issues before push |

### Cross-References to Add

- `feedback:write-api` should reference `feedback:implement-new-api-changes` (and vice versa) to prevent Claude from writing feedback when implementation is expected
- `plan:feature` should reference `plan:dry` as a mandatory follow-up step
- `bugs:collect` should reference `bugs:fix` for the execution step
- `analyze:run-and-fix` should reference `analyze:improve-exceptions` for follow-up

---

## Priority Order

Ranked by: (sessions affected) x (friction reduced) = expected impact

| Priority | Action | Impact Score | Effort |
|----------|--------|-------------|--------|
| **P1** | Enhance `feedback:implement-new-api-changes` with guardrails | 12 sessions x 3 friction types = **36** | Low — edit existing file |
| **P2** | Create `convention:check` command | 40+ sessions x 2 friction types = **80** | Medium — new command |
| **P3** | Enhance `plan:feature` with convention checking | 22 sessions x 1 friction type = **22** | Low — edit existing file |
| **P4** | Enhance `bugs:fix` with TDD workflow | 29 sessions x 1 friction type = **29** | Low — edit existing file |
| **P5** | Enhance `validate:pre-commit` with DI/translation checks | All commit sessions x 1 friction type = **41** | Medium — add checks |
| **P6** | Create `tdd:bugfix` command | 29 sessions x 1 friction type = **29** | Medium — new command |
| **P7** | Create `dry:check` command | 10 sessions x 1 friction type = **10** | Medium — new command |
| **P8** | Enhance `git:commit` with logical grouping | 41 sessions x 1 friction type = **41** | Low — edit existing file |
| **P9** | Create `feedback:implement-safe` (if P1 insufficient) | 12 sessions x 3 = **36** | Medium — new command |
| **P10** | Add cross-references between related commands | All sessions = awareness | Low — edit files |

---

## Recommended First Actions

1. **Quick win**: Add guardrail lines to `feedback:implement-new-api-changes` (P1) — 10 minutes of editing, prevents the #1 friction pattern
2. **Quick win**: Add convention-check step to `plan:feature` (P3) — prevents wrong-approach detours
3. **Medium lift**: Build `convention:check` command (P2) — reusable across all implementation workflows
4. **Medium lift**: Add TDD steps to `bugs:fix` (P4) — prevents buggy code from shipping

Do NOT auto-implement. Review priorities and decide what to act on.
