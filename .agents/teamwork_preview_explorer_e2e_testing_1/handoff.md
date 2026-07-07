# Handoff Report: E2E Test Suite Design and Proposal

## 1. Observation
- **Observation 1 (Existing Test Runner)**: `tests/MicroTestRunner.gd` line 1 extends `Node`.
  ```gdscript
  extends Node
  class_name MicroTestRunner
  ```
- **Observation 2 (Godot Execution Error)**: Running `tests/TestEconomy.gd` (which extends `MicroTestRunner` -> `Node`) using Godot's `-s` command line option:
  `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/TestEconomy.gd`
  yields the error:
  ```
  ERROR: Can't load the script "tests/TestEconomy.gd" as it doesn't inherit from SceneTree or MainLoop.
     at: start (main/main.cpp:4286)
  ```
- **Observation 3 (Economy Load/Save State)**: `scripts/managers/EconomyManager.gd` lines 44-45 calls `load_game()` inside `_ready()`:
  ```gdscript
  func _ready() -> void:
  	load_game()
  ```
  And lines 72-85 calls `save_game()` on every upgrade purchase.
- **Observation 4 (Game Node Initialization & Connections)**: `scenes/main/Game.gd` lines 3-12 has `@onready` bindings (e.g. `economy_manager = $EconomyManager`).
- **Observation 5 (Urgent News Coords)**: `scenes/main/Game.gd` lines 201-205 calculates spawn coordinates using viewport size:
  ```gdscript
  var max_x = max(100.0, size.x - 400.0)
  var max_y = max(200.0, size.y - 200.0)
  ```

---

## 2. Logic Chain
1. From **Observation 1** and **Observation 2**, we establish that any script run via Godot's `-s` option must inherit from `SceneTree` or `MainLoop`. A script extending `Node` cannot be launched directly as the main entry script. Therefore, a custom headless E2E test runner (`tests/E2ETestRunner.gd`) must inherit from `SceneTree`.
2. Because constructor `_init()` in GDScript does not support coroutines (`await`), executing asynchronous E2E tests directly in `_init()` will crash. By using `call_deferred("_run_all_tests")`, we shift execution to the first process frame of the SceneTree, where asynchronous operations (`await`) are fully supported.
3. From **Observation 3**, we recognize that `EconomyManager` loads game files on ready and saves them on upgrades. If tests run sequentially without deleting the `user://savegame.save` file, stale states will leak between tests and override local developer data. Thus, the setup and teardown of the E2E tests must forcefully remove `user://savegame.save` via `DirAccess.remove_absolute()`.
4. From **Observation 4**, we know that game nodes and singletons are initialized when added to the scene tree. To mock dependencies like `LocalLLMClient` cleanly, we should instantiate `Game.tscn` but replace the production client node with a `MockLocalLLMClient` *before* adding the game node to the SceneTree. This ensures that the game's `@onready` variables automatically bind to the mock instance without needing production code modifications.
5. From **Observation 5**, we see that UI coordinates are dependent on window size. E2E tests must ensure the game scene size is initialized to a standard size (e.g., 1080x1920) before node entry to prevent negative bounds or placement errors in headless executions.

---

## 3. Caveats
- **Headless Window Behaviors**: Tween animations (`create_tween()`) run normally in headless mode but will not output any visual viewport frames. Tests checking visual tweens must monitor properties (like scale, positions, alpha) over process frames.
- **Mocking Assumptions**: We assume the planned `LocalLLMClient` interface will follow standard async patterns: taking `topic` and `prompt` parameters, and emitting signals (`speech_generated` and `generation_failed`). If the implementation interface changes, the mock classes in the proposal must be adjusted accordingly.

---

## 4. Conclusion
We propose a headless E2E test suite consisting of:
1. `tests/E2ETestRunner.gd`: Main runner script inheriting from `SceneTree`.
2. `tests/e2e/E2ETestBase.gd`: Base test script providing clean environment isolation, save-state removal, and assertion utilities.
3. `tests/mocks/MockLocalLLMClient.gd`: Dynamic mock client simulating successful and failed asynchronous LLM speech generations.
4. **71 Test Cases** mapped across 4 tiers of coverage (Feature Coverage, Boundary/Corner, Cross-Feature, and Real-World playthroughs) covering all 6 core features.

Implementing this architecture will resolve command-line execution blocks and provide robust validation of the codebase.

---

## 5. Verification Method
1. Inspect the layout recommendations in `analysis.md` inside this directory:
   `c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\teamwork_preview_explorer_e2e_testing_1\analysis.md`
2. Once the files are created by the implementer, run the following command to execute the E2E tests:
   `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd`
3. Verify that the runner logs output, runs tests sequentially, cleans save files, and exits with code 0 on success.
