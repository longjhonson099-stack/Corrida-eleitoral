# E2E Test Suite Recommendations - Handoff Report

## 1. Observation
During the exploration of the "Corrida Eleitoral de Brasílica" codebase, I observed the following details:
*   **Project File Structure**: Consists of standard Godot 4 folders (`scenes/`, `scripts/`, `assets/`, `tests/`) as listed in `PROJECT.md` and verified through directory listing.
*   **Game Controller (`scenes/main/Game.gd`)**: Handles UI actions, timers, and game progression:
    *   Line 3: `@onready var economy_manager = $EconomyManager`
    *   Line 79: `func _on_btn_generate_pressed() -> void:` manages manual clicking by adding discursos and modifying `global_score_red` by 0.2.
    *   Lines 113–119: `_simulate_enemy_faction()` adds `0.5 + 0.04 * dps` to `global_score_blue` every second.
    *   Line 126: `var red_percent: float = (global_score_red / total) * 100.0`
    *   Lines 219–232: `_on_btn_urgent_news_pressed()` handles the Fake News click bonus (`max(100.0, dps * 30.0)`).
*   **Save System (`scripts/utils/SaveManager.gd`)**: Uses `const SAVE_FILE = "user://savegame.save"`.
*   **Existing Test Setup**: `tests/` contains `MicroTestRunner.gd` (inheriting from `Node`), `TestEconomy.gd`, and `TestSaveSystem.gd`. There are no active E2E tests or automated headless runners in place.
*   **Planned LLM Integration (`PROJECT.md` Line 21)**: Spec outlines `LocalLLMClient` with `generate_speech_async(topic, prompt)` method and `speech_generated` / `generation_failed` signals.

## 2. Logic Chain
1. **Runner Base Class Selection**: Headless execution with the `-s` command requires the script to inherit from `SceneTree` (rather than `Node`) to obtain a runtime viewport tree and command-line execution authority.
2. **Game Environment Setup**: To perform E2E testing on UI components and signals, `Game.tscn` must be instantiated and added to the root node (`root`) of the `SceneTree` inside the runner.
3. **Data Protection / Isolation**: Since `AppSaveManager` writes directly to `user://savegame.save`, running tests would overwrite active user progress. The runner must backup the developer's save files to `user://savegame.save.bak` during initialization and restore it upon termination.
4. **Asynchronous Execution**: In-game actions like news timers, tween transitions, and async LLM API calls require non-blocking waits. The E2E runner must support `await` and process frame advances using `await process_frame` to evaluate states after signal emissions.
5. **Decoupling Network Dependencies**: Since the local LLM Ollama server might not be running in testing/CI/CD environments, E2E tests targeting the planned speech feature must use a Mock class (`MockLocalLLMClient`) that exposes the same interface but fires signals deterministically.
6. **Robust Test Coverage**: To meet the requirement of 71+ test cases, I defined exactly 30 Tier 1 tests (5 per feature), 30 Tier 2 tests (boundary/corner case testing), 6 Tier 3 tests (cross-feature interactions), and 5 Tier 4 tests (full gameplay playthroughs).

## 3. Caveats
*   **LocalLLMClient Implementation**: Since `LocalLLMClient.gd` is not yet implemented (planned for Milestone 2), the LLM test recommendations are built entirely on the planned interface contracts defined in `PROJECT.md`.
*   **UI Tweens/Animations**: In headless mode, visual elements are simulated in memory but not rendered on screen. Some UI tweens might resolve instantly or process on frame ticks. E2E tests should assert on the backing data state or child node existence rather than actual visual pixel colors.

## 4. Conclusion
We recommend establishing `tests/E2ETestRunner.gd` (inheriting from `SceneTree`) as the core headless E2E driver, with `tests/E2ETestCase.gd` (inheriting from `Node`) as the base test class. By isolating save states, dynamically discovering test scripts under `tests/e2e/`, and simulating UI signals via `pressed.emit()`, the project can run reliable, headless E2E testing. The detailed suite of 71 test cases ensures full coverage of features, boundary inputs, integration logic, and real playthrough simulations.

## 5. Verification Method
1. Inspect the layout recommendations and the 71 test cases written in `c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\teamwork_preview_explorer_e2e_testing_2\analysis.md`.
2. Verify that `tests/E2ETestRunner.gd` inherits from `SceneTree` and manages save backups/restorations correctly.
3. Verify that the 71 test cases are structured across 4 distinct Tiers covering all 6 key features.
