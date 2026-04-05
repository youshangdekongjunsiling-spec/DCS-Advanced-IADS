# Skynet Main Agent Governance

## Purpose

This document defines how the main agent manages multi-threaded implementation work for the DCS `Skynet-IADS` customization project.

The user provides only a task list.
The main agent is responsible for:

- turning the task list into executable subtasks
- defining implementation boundaries for each subtask
- defining verification and rollback points
- maintaining strict version checkpoints
- generating prompt packages for child threads
- checking whether each child thread actually completed its assigned scope

This document is the control contract for all future subtasks unless the user explicitly overrides it.

## Ground Rules

- The mission `.miz` files are not modified unless the user explicitly asks for it.
- The real runtime import target is:
  - `c:\Users\yuanh\Desktop\DCS现代化空地对抗\skynet-iads-compiled-ea18g.lua`
- Source-of-truth code lives under:
  - `c:\Users\yuanh\Desktop\DCS现代化空地对抗\Skynet-IADS\skynet-iads-source`
- Setup-side mission policy lives in:
  - `c:\Users\yuanh\Desktop\DCS现代化空地对抗\my-iads-setup.lua`
- Every subtask must end with:
  - source change
  - recompiled import file
  - one isolated checkpoint commit
  - a concise validation note

## Version Management Rules

### Checkpoint Strategy

For every user-approved subtask:

1. Create or identify a clean baseline checkpoint before editing.
2. Implement only that subtask.
3. Recompile runtime script.
4. Save one isolated commit for that subtask.
5. Record:
   - commit hash
   - compiled banner
   - affected files
   - rollback target

### Commit Scope Rules

- One subtask, one commit.
- No mixed commits across unrelated features.
- Bugfixes caused by the subtask itself belong in the same subtask commit only if they are strictly necessary to make that subtask usable.
- Any newly discovered unrelated defect must be documented, not silently folded into the current commit.

### Runtime Banner Rule

Every meaningful subtask build should update the compiled banner so test logs can be tied to the exact implementation.

Banner format:

`ea18g-<feature>-<variant>`

Examples:

- `ea18g-msam-height-gate`
- `ea18g-family-rotation-1000m`
- `ea18g-family-rotation-lock-cover-hardfix`

## Code Split Rules

### Allowed Write Scope Per Subtask

Each subtask must declare its write scope before implementation.

Typical allowed write scopes:

- `skynet-iads-mobile-patrol.lua`
- `skynet-iads-sibling-coordination.lua`
- `skynet-iads-abstract-radar-element.lua`
- `skynet-iads-harm-detection.lua`
- `my-iads-setup.lua`
- compiled output file

The child thread should not expand beyond the declared files unless the main agent explicitly approves the expansion.

### Isolation Rule

If a subtask requires touching both behavior logic and diagnostics:

- keep diagnostics limited to the same behavior area
- do not opportunistically redesign unrelated logging systems

## Completion Rules

A subtask is only considered complete if all of the following are true:

- the requested scope is implemented
- the compiled import file is regenerated
- the compiled banner matches the subtask build
- the subtask has an isolated commit
- runtime logs or user test feedback are consistent with the intended change

A subtask is **not** complete if:

- only source changed, but compiled output was not refreshed
- compiled output changed, but source-of-truth files did not
- logs do not confirm expected execution path
- the feature works only in part but is reported as finished

## Child Thread Package Format

When the user wants separate threads, the main agent should prepare each child task using this format.

### 1. Subtask Name

Short operational label.

Example:

`Subtask 2A: Family Rotation Cover Lock`

### 2. Objective

One paragraph:

- what must change
- what must not change
- what success looks like

### 3. Allowed Files

Explicit file list.

Example:

- `Skynet-IADS/skynet-iads-source/skynet-iads-sibling-coordination.lua`
- `Skynet-IADS/demo-missions/skynet-iads-compiled.lua`
- `skynet-iads-compiled-ea18g.lua`

### 4. Forbidden Scope

Examples:

- do not touch `.miz`
- do not redesign unrelated HARM logic
- do not rewrite logging outside the target feature

### 5. Required Diagnostics

Specify exact runtime evidence expected.

Example:

- must emit `family_rotation_start`
- must no longer emit `reactivated:nearest_trigger`

### 6. Required Save Point

Child thread must report:

- commit hash
- banner
- hash or at least confirmation that root compiled file was refreshed

### 7. Required Final Report

Flat checklist:

- changed files
- commit hash
- runtime banner
- what remains risky

## Child Prompt Template

Use this template when spawning a child thread manually by copy/paste:

```text
You are working on exactly one isolated subtask in the DCS Skynet workspace.

Subtask:
<subtask name>

Objective:
<precise objective>

Allowed files:
<explicit list>

Forbidden scope:
<explicit list>

Runtime target:
c:\Users\yuanh\Desktop\DCS现代化空地对抗\skynet-iads-compiled-ea18g.lua

Rules:
- Do not touch `.miz`.
- Do not change files outside the allowed list unless strictly necessary and explicitly justified.
- Recompile the runtime script after source edits.
- Save one isolated commit for this subtask only.
- In the final report, include commit hash, banner, changed files, and whether runtime evidence matches the requested behavior.

Required diagnostics:
<required log keys or runtime evidence>

Done means:
<concrete acceptance conditions>
```

## Main Agent Review Checklist

When a child thread returns, the main agent must verify:

1. Did it stay within scope?
2. Did it produce an isolated commit?
3. Did it actually refresh the root compiled runtime file?
4. Does the banner match the claimed implementation?
5. Do the logs support the claimed behavior?
6. Did it accidentally regress another protected feature?

If any answer is no, the subtask is not accepted yet.

## Status Ledger Template

Use the following section format for real task batches.

### Batch

- batch_id:
- baseline_commit:
- baseline_banner:
- mission_runtime_target:

### Subtasks

| id | name | status | commit | banner | scope | verification |
|---|---|---|---|---|---|---|
| T1 | pending | pending | - | - | - | - |

Status values:

- `planned`
- `approved`
- `in_progress`
- `implemented`
- `verified`
- `rejected`
- `rolled_back`

## Current Stable Checkpoint

As of the creation of this governance document, the latest stable checkpoint reported by the main agent is:

- commit: `04b895a`
- banner: `ea18g-family-rotation-lock-cover-hardfix`

This section must be updated whenever the user explicitly confirms a new stable node.
