# Headless E2E Test Infrastructure & Test Suite

This document details the E2E test runner, architecture, and feature coverage for the "Corrida Eleitoral de Brasílica" project.

## Feature Inventory (N = 6 features)

1. **Manual Clicker**
   - Click to generate discursos (`_on_btn_generate_pressed()`).
   - Increments red faction score (`global_score_red`) and updates Tug-of-War bar.
   - Triggers UI animations (BtnGenerate scale) and floating text.

2. **Upgrades**
   - Data-driven economy management (`EconomyManager.gd`).
   - Incremental costs following the formula $Cost = BaseCost \times 1.15^{Count}$.
   - Increments automatic speech generation rate (DPS).

3. **Prestige**
   - Multiplier increments by +0.5 per reset.
   - Resets discursos count and all upgrade levels back to 0.
   - Future upgrade values and manual clicks scale with the new multiplier.

4. **Fake News**
   - Urgent news button spawns at random intervals and positions.
   - Grants a large instantaneous discursos bonus scaled with current DPS.
   - Vanishes after a short delay via tween fade.

5. **LLM Speech Generation**
   - Async generation using planned `LocalLLMClient` API.
   - Transition to UI "thinking" state.
   - Signal handling for success (`speech_generated`) and failure (`generation_failed`) with timeouts.

6. **Tug-of-War Win/Loss**
   - Faction balance calculated dynamically: $Red\% = \frac{RedScore}{RedScore + BlueScore} \times 100$.
   - Red faction reaching $\ge 99.9\%$ triggers a Victory Screen.
   - Blue faction reaching $\ge 99.9\%$ (Red $\le 0.1\%$) triggers a Defeat Screen.

## Test Runner Architecture

The test runner is built in `tests/E2ETestRunner.gd` and executes inside headless Godot.

- **SceneTree-based execution**: Inherits from `SceneTree` to execute programmatically without the GUI window.
- **Save State Isolation**: Backs up `user://savegame.save` to `user://savegame.save.backup` at startup, deletes it for a clean run, and restores the backup at exit.
- **Dynamic Test Scanning**: Recursively scans `tests/e2e/` for any files starting with `test_` and ending with `.gd`.
- **Sequential Execution**: Instantiates the Game scene (`Game.tscn`), adds it to the root viewport, instantiates the test case script, runs all its methods starting with `test_` sequentially, asserts, cleans up, and moves to the next.
- **Exit Codes**: Quits Godot with exit code `0` on success and `1` on failure.

## Execution Command

```powershell
C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd
```
