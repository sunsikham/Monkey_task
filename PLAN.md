# Refactor Plan (Mild Milestones)

## Milestone 1 — Baseline + Safety
- Freeze current behavior with a short "smoke list" (what should still work).
- Identify all entry points (`New_task`, `run_session`) and current data flow.
- Write a small checklist for manual testing (calibration, choice, pursuit, reward, save).

## Milestone 2 — Separate Configuration vs. Runtime
- Move experiment settings (pairs, random/block switch, timings) into one config struct or file.
- Keep runtime state (`state`, `prev_trial_idx`, `last_correct`) separate from config.
- Make a single "session options" struct passed into `New_task`.

## Milestone 3 — Isolate IO / Side Effects
- Isolate file I/O (load/save trial, metadata, gain/offset) into helper functions.
- Centralize all PTB window creation/cleanup in one place (already mostly done).
- Ensure functions do not change global paths or globals unless necessary.

## Milestone 4 — Split `New_task` into Clear Phases
- Create small functions:
  - `setup_session` (keyboard, paths, initial state)
  - `run_trial` (ITI → CHOICE → PURSUIT → SCORE)
  - `save_trial` (single responsibility)
- Keep `New_task` as a thin orchestrator.

## Milestone 5 — Cleanup and Consistency
- Standardize names (`visual_opt`, `device_opt`, `game_opt`) across files.
- Remove unused variables or dead branches.
- Add lightweight comments where logic is non-obvious.

## Milestone 6 — Verification
- Run through the manual checklist from Milestone 1.
- Compare behavior with baseline (screen layout, gaze window, reward, saving).

